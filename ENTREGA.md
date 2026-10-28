# Entrega: app FastAPI de trámites

## Archivos
- `app/main.py`: la API (GET /health y GET /tramites/{numero}), modelos Pydantic, datos simulados en memoria, lectura de API_KEY como `SecretStr` y arranque con uvicorn en 0.0.0.0:$PORT (8080 por defecto).
- `app/__init__.py`: marca `app` como paquete (vacío).
- `pytest.ini`: configura la raíz de imports y el directorio de pruebas.
- `tests/test_main.py`: pruebas con pytest y TestClient (200, 404, 422 y que API_KEY no se exponga).
- `requirements.txt`: dependencias de ejecución con versiones fijas.
- `requirements-dev.txt`: incluye requirements.txt y añade pytest y httpx (lo necesita TestClient).
- `.env.example`: variables esperadas, sin valores.

## Datos simulados
| numero | estado |
|---|---|
| TR-001 | recibido |
| TR-002 | en_proceso |
| TR-003 | completado |

El número se valida con el patrón `^[A-Za-z0-9-]+$` (máx. 20 caracteres) y no distingue mayúsculas; un formato inválido devuelve 422.

## Comandos
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements-dev.txt
python -m pytest -v                      # pruebas
python -m app.main                       # escucha en 0.0.0.0:8080
PORT=9090 API_KEY=xxx python -m app.main # puerto y clave por entorno
curl localhost:8080/health
curl localhost:8080/tramites/TR-002
```

## Resultado real (Python 3.13.17)
```
7 passed, 1 warning in 0.43s
```
También se arrancó el servidor con PORT=9090 y respondió 200 en /health, 200 en /tramites/TR-002 y 404 en /tramites/X.

## Limitaciones conocidas
- Aviso `StarletteDeprecationWarning`: Starlette 1.10 recomienda `httpx2` en lugar de `httpx` para TestClient. No afecta las pruebas; no se cambió porque no se pudo instalar `httpx2` en este entorno.
- API_KEY se lee pero no se usa en ningún endpoint, porque no se pidió autenticación. Si falta, queda como cadena vacía.
- Las versiones fijadas son solo las directas; las dependencias transitivas (starlette, anyio, etc.) no están bloqueadas.
- `.gitignore` excluye entornos, cachés y patrones habituales de credenciales.
- Los datos se pierden al reiniciar (son en memoria por diseño).

## Auditoría local posterior

Python 3.14.4: 8 passed, 1 warning en 0.29s. HTTP real con Uvicorn en
9090: salud y tres trámites 200, inexistente 404 y formato inválido 422.
Clave sintética ausente de respuestas y logs capturados. Los resultados anteriores
con Python 3.13 son antecedentes de la entrega y no pruebas repetidas en este entorno.
