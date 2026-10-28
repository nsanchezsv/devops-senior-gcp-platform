# API de trámites — etapa 01

FastAPI con datos simulados en memoria. Validada localmente con Python 3.14.4.
El despliegue en Cloud Run, Terraform y GitHub Actions corresponde a etapas futuras.

## Ejecución local

```bash
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements-dev.txt
python -m pytest -v
PORT=8080 python -m app.main
```

En Debian/Ubuntu se requiere el paquete python3-venv correspondiente al intérprete.
Si falta ensurepip, se puede instalar en el entorno creado mediante
`python3 -m pip --python .venv/bin/python install -r requirements-dev.txt`.
También puede iniciarse con `.venv/bin/python -m uvicorn app.main:app --host 0.0.0.0 --port 8080`.

## Configuración y endpoints

`.env.example` contiene únicamente nombres y valores no sensibles. La aplicación no carga
archivos .env automáticamente: exportar las variables en el shell.
`PORT` vale 8080 por defecto. `API_KEY` se lee al importar el módulo, se almacena como
SecretStr y queda vacía si no se configura. Actualmente no implementa autenticación.
No registrar ni devolver su valor. En Cloud Run se prevé inyectarla desde Secret Manager.

| Solicitud | Resultado |
|---|---|
| GET /health | 200, status healthy |
| GET /tramites/TR-001 | 200, recibido |
| GET /tramites/TR-002 | 200, en_proceso |
| GET /tramites/TR-003 | 200, completado |
| GET /tramites/X | 404 |
| GET /tramites/invalid_ | 422 |

Los números no distinguen mayúsculas, admiten letras ASCII, números y guiones,
y tienen un máximo de 20 caracteres. Documentación interactiva en /docs.

## Validación realizada

Auditoría local: 8 pruebas pasaron, con una advertencia de deprecación de Starlette
por el uso de httpx en TestClient. Pruebas HTTP reales con Uvicorn y PORT=9090:
los seis casos de la tabla respondieron como se esperaba. No se observó la clave
sintética en respuestas ni logs capturados. El sandbox bloqueó la ejecución inicial;
las verificaciones satisfactorias se ejecutaron con autorización fuera del sandbox.

Las versiones directas fijadas se instalaron correctamente. Las dependencias transitivas
no están bloqueadas; no se ha realizado un análisis de vulnerabilidades.
Los datos son estáticos y no hay persistencia. La autenticación y los controles de
producción deberán definirse antes de exponer datos reales.
