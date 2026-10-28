import subprocess as sp, json, time, urllib.request, urllib.error, tarfile, io, re
from pathlib import Path

def docker(*args):
    return sp.check_output(['docker', *args], stderr=sp.STDOUT).decode()

image='devops-02-audit:local'
info=json.loads(docker('image','inspect',image))[0]
print('IMAGE',info['Id'],'BYTES',info['Size'],'MiB',round(info['Size']/1024**2,2))
assert info['Config']['User']=='10001:10001'
print('ENV',info['Config']['Env'])
probe='''import os,importlib.metadata as m,json
assert os.getuid()==os.getgid()==10001
status=dict(line.strip().split(':',1) for line in open('/proc/1/status') if ':' in line)
assert all(int(status[k].strip(),16)==0 for k in ('CapInh','CapPrm','CapEff','CapBnd','CapAmb'))
assert status['NoNewPrivs'].strip()=='1'
print('PASS UID/GID=10001, all capabilities=0, NoNewPrivs=1')
for path in ['/tmp/audit-write','/app/audit-write']:
 try:
  open(path,'w').close()
  raise AssertionError(path+' writable')
 except OSError as e:
  assert e.errno==30,e
print('PASS read-only /tmp and /app; no tmpfs')
assert set(os.listdir('/app/app'))=={'main.py','__init__.py'},os.listdir('/app/app')
assert os.stat('/app/app/main.py').st_uid==0
packages=sorted((d.metadata['Name'],d.version) for d in m.distributions())
assert not {'pytest','httpx','httpx2','coverage','pytest-cov'} & {n.lower() for n,v in packages}
print('PASS code root-owned; no bytecode, tests or testing packages',json.dumps(packages))
'''
for port in (9090,8080):
    args=['run','-d','--read-only','--cap-drop=ALL','--security-opt=no-new-privileges:true','-p',f'127.0.0.1::{port}']
    if port==9090:
        args+=['-e','PORT=9090','-e','API_KEY=audit-synthetic-only']
    cid=docker(*args,image).strip()
    try:
        mapping=json.loads(docker('inspect',cid))[0]['NetworkSettings']['Ports'][f'{port}/tcp'][0]
        url='http://127.0.0.1:'+mapping['HostPort']
        for attempt in range(50):
            try:
                urllib.request.urlopen(url+'/health',timeout=1).close()
                break
            except (OSError,urllib.error.URLError): time.sleep(.1)
        for path,expected in [('/health',200),('/tramites/TR-001',200),('/tramites/TR-002',200),('/tramites/TR-003',200),('/tramites/X',404),('/missing',404),('/tramites/invalid_',422),('/openapi.json',200)]:
            try: r=urllib.request.urlopen(url+path,timeout=3)
            except urllib.error.HTTPError as e: r=e
            body=r.read().decode()
            assert r.status==expected,(path,r.status)
            assert 'audit-synthetic-only' not in body
            print('PASS HTTP',port,path,r.status)
        print(docker('exec',cid,'python','-c',probe))
        print(docker('exec',cid,'python','-m','pip','check'))
        logs=docker('logs',cid)
        assert f'0.0.0.0:{port}' in logs
        assert 'audit-synthetic-only' not in logs
        print('PASS bind/logs',port)
        docker('stop','--time','5',cid)
        assert json.loads(docker('inspect',cid))[0]['State']['ExitCode']==0
        print('PASS graceful SIGTERM')
    finally:
        docker('rm','-f',cid)
# Inspect every saved layer, including files hidden by later layers.
archive=sp.check_output(['docker','save',image])
patterns=re.compile(rb'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----|AKIA[0-9A-Z]{16}|"type"\s*:\s*"service_account"|"private_key"\s*:')
with tarfile.open(fileobj=io.BytesIO(archive)) as saved:
    manifest=json.load(saved.extractfile('manifest.json'))[0]
    config=saved.extractfile(manifest['Config']).read()
    assert not patterns.search(config)
    assert b'audit-synthetic-only' not in config
    layers=manifest['Layers']
    app_files=[]
    for layer in layers:
        with tarfile.open(fileobj=saved.extractfile(layer),mode='r|*') as tar:
            for member in tar:
                name=member.name.removeprefix('./')
                assert not re.search(r'(^|/)(\.env(?:\..*)?|\.aws|\.git|credentials\.json|application_default_credentials\.json)(/|$)',name),name
                if name.startswith('app/') and member.isfile():
                    app_files.append(name)
                    content=tar.extractfile(member).read()
                    assert not patterns.search(content),name
                    assert b'audit-synthetic-only' not in content,name
    assert sorted(app_files)==['app/app/__init__.py','app/app/main.py'],app_files
    print('PASS layer audit',len(layers),'layers; app files',app_files)
print('PASS scoped secret audit: config/history, sensitive paths in all layers, project source content; not a full secret/CVE scanner')
import tempfile
with tempfile.TemporaryDirectory(prefix='devops02-context-') as directory:
    result=sp.run(['docker','build','--no-cache','-f','-','--output','type=local,dest='+directory,'.'],input=b'FROM scratch\nCOPY . /\n',stdout=sp.PIPE,stderr=sp.STDOUT,check=True)
    files=sorted(str(p.relative_to(directory)) for p in Path(directory).rglob('*') if p.is_file())
    assert files==['.dockerignore','Dockerfile','app/__init__.py','app/main.py','requirements.txt'],files
    print('PASS actual Docker build context',files,'(allowlist verified)')
