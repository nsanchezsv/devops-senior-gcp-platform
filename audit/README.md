# Auditoría Docker — DEVOPS-02

Fecha: 2026-10-28. Rama: `feature/DEVOPS-02-docker`. Plataforma: Linux amd64.

**Dictamen: apto para merge de la etapa Docker**, con los ajustes presentes en el
workspace. No se detectaron fallos funcionales. No equivale a aprobar la exposición
pública de datos reales ni a certificar ausencia de vulnerabilidades.

## Evidencia

Imagen final: `devops-02-audit:local`.
ID: `sha256:8d19084113abc78258653566f4978149c8e036b4894b473814e361063cb3ed8c`.
Tamaño local sin comprimir: **147312045 bytes = 140,49 MiB**; no es el tamaño de descarga.

| Comprobación | Resultado | Evidencia |
|---|---|---|
| Dockerfile multistage | PASS | Etapas `builder` y `runtime`; solo se copia el venv y el código al runtime. |
| Base con versión fija | PASS | Ambas etapas usan `python:3.14.4-slim`; build resolvió `sha256:2ca02f32b4d9d893863367ce07ec1972819f476dd38d8612f2a9cb6a41cbb727`. La etiqueta no garantiza inmutabilidad. |
| Construcción real | PASS | `docker build --no-cache --progress=plain -t devops-02-audit:local .`; descarga e instalación satisfactorias. |
| Comprobaciones BuildKit | PASS | `docker build --check .`: `Check complete, no warnings found.` |
| Usuario no-root | PASS | Configuración `10001:10001`; UID/GID reales del proceso: 10001. Código y dependencias pertenecen a root. |
| Contexto seguro | PASS tras corrección | Extracción real del contexto: `.dockerignore`, `Dockerfile`, `requirements.txt`, `app/__init__.py`, `app/main.py`. |
| Dependencias de producción | PASS | FastAPI 0.162.0, Pydantic 2.14.1 y Uvicorn 0.54.0; sin pytest, httpx, httpx2, coverage o pytest-cov. `pip check`: `No broken requirements found.` |
| Contrato de red Cloud Run | PASS local | HTTP desde el host en 8080 por defecto y con `PORT=9090`; logs confirman `0.0.0.0` en ambos. No se realizó despliegue. |
| Solo lectura | PASS | `--read-only`, sin volúmenes ni tmpfs; escribir en `/app` y `/tmp` devuelve errno 30 (EROFS). |
| Capacidades y privilegios | PASS | `--cap-drop=ALL --security-opt=no-new-privileges:true`; CapInh/Prm/Eff/Bnd/Amb = 0 y NoNewPrivs = 1 en `/proc/1/status`. |
| HTTP 200 | PASS | `/health`, `/tramites/TR-001`, `/tramites/TR-002`, `/tramites/TR-003`, `/openapi.json`, en ambos puertos. |
| HTTP 404 | PASS | `/tramites/X` y `/missing`, en ambos puertos. |
| HTTP 422 | PASS | `/tramites/invalid_`, en ambos puertos. |
| Apagado | PASS | SIGTERM mediante `docker stop --time 5`: salida 0 en ambos puertos. Python/Uvicorn es PID 1. |
| Secretos, revisión acotada | PASS | Configuración/historial sin marcadores de credenciales; ocho capas sin rutas sensibles buscadas; código de aplicación sin patrones de claves privadas, claves AWS AKIA o JSON de cuenta de servicio. Solo dos archivos de aplicación en las capas. |
| Secreto inyectado | PASS | Valor sintético inyectado al ejecutar, ausente de respuestas, logs y configuración de imagen. No se utilizó una credencial real. |
| Pruebas de aplicación | PASS | `.venv/bin/python -m pytest -q`: **8 passed, 1 warning in 0.28s**. |
| Escaneo CVE y escáner completo de secretos | NO EJECUTADO | Trivy/Grype no están instalados. La revisión acotada no demuestra ausencia absoluta de secretos ni vulnerabilidades en paquetes/base. |

Salida de la auditoría final: [docker-audit.log](docker-audit.log).
Comprobador reproducible: [docker_audit.py](docker_audit.py). Usa solo la biblioteca
estándar del host y Docker; crea y elimina sus propios contenedores temporales y
extrae el contexto a un directorio temporal. La imagen debe estar construida primero.

```bash
docker build --no-cache --progress=plain -t devops-02-audit:local .
docker build --check .
python3 audit/docker_audit.py
.venv/bin/python -m pytest -q
```

El primer intento de pytest dentro del sandbox quedó sin completar. La ejecución
fuera del sandbox terminó con las ocho pruebas satisfactorias indicadas. La
advertencia de Starlette sobre TestClient/httpx corresponde al entorno de desarrollo;
no afecta a la imagen, que carece de ambos clientes de testing. `pip check` emite un
aviso de caché no escribible en el usuario sin home; la aplicación no usa pip al iniciar.

## Hallazgos corregidos

- **FAIL inicial: exclusiones incompletas.** La lista original no cubría `.aws`,
  credenciales con nombres alternativos ni archivos sensibles arbitrarios bajo `app`.
  Se cambió a una lista de inclusión de los archivos necesarios. La verificación del
  contexto real confirma las exclusiones. Los módulos Python nuevos directamente
  bajo `app` se incluyen; si se agregan subpaquetes o recursos, ajustar esta lista.
- **FAIL inicial: bytecode local incluido.** La primera imagen contenía
  `app/__pycache__`; la final contiene únicamente los dos fuentes Python.
- Se retiró `--chown=appuser:appgroup` del código: el usuario de ejecución no necesita
  modificarlo. Esto también protege el código al ejecutar sin `--read-only`.

No fue necesario modificar la lógica FastAPI ni sus dependencias para hacerla funcionar.
La primera expectativa del comprobador de contexto omitía Dockerfile y .dockerignore;
se corrigió esa expectativa y se repitió satisfactoriamente la auditoría completa.

## Recomendaciones proporcionadas

1. Mantener las opciones de ejecución probadas al usar Docker local:
   `--read-only --cap-drop=ALL --security-opt=no-new-privileges:true`.
   Son opciones del runtime, no garantías impuestas por Dockerfile. La base conserva
   binarios SUID/SGID habituales de Debian; `no-new-privileges` impide aprovecharlos
   para elevar privilegios en la configuración validada. No se requiere una base propia.
2. Antes de producción, escanear la imagen con una base CVE actualizada y gestionar
   actualizaciones de Python/Debian y dependencias. No se puede declarar la imagen
   libre de CVE con estas pruebas.
3. Para builds reproducibles, fijar el digest de la base junto con la etiqueta y
   bloquear dependencias transitivas con hashes. Mantener un proceso sencillo de
   actualización; las versiones directas ya están fijadas.
4. El venv ocupa aproximadamente 32 MiB y contiene pip. El Python de la base también
   incluye pip (aproximadamente 6,5 MiB). Si el tamaño resulta relevante, evaluar crear
   el venv sin pip e instalar desde el builder con `pip --python`; medir y repetir las
   pruebas antes de cambiarlo. Eliminar archivos de la base en capas posteriores no
   reduce sus capas descargables. El tamaño actual es razonable para esta API;
   no se justifica migrar a Alpine/distroless ni eliminar herramientas indiscriminadamente.
5. Seguir inyectando secretos al ejecutar, sin `ARG`, `ENV` con valores reales ni
   archivos copiados. La API actual no implementa autenticación; definirla antes de
   exponer datos reales, fuera del alcance de esta etapa Docker.

El contrato de Cloud Run exige escuchar en el PORT inyectado y en 0.0.0.0:
[documentación oficial](https://docs.cloud.google.com/run/docs/container-contract).
Docker explica las etiquetas mutables y la fijación por digest en sus
[buenas prácticas](https://docs.docker.com/build/building/best-practices/).

No se ejecutaron git add, commit, push, merge, Terraform ni despliegues a GCP.
Dockerfile y .dockerignore ya estaban sin seguimiento al comenzar; siguen sin añadir.
