# syntax=docker/dockerfile:1

# Stage 1: construir entorno de dependencias
FROM python:3.14.4-slim AS builder

WORKDIR /build

RUN python -m venv /opt/venv

ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt


# Stage 2: imagen de ejecución
FROM python:3.14.4-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT=8080

WORKDIR /app

RUN groupadd --gid 10001 appgroup \
    && useradd --uid 10001 --gid appgroup \
       --no-create-home --shell /usr/sbin/nologin appuser

COPY --from=builder /opt/venv /opt/venv
# El código pertenece a root; el usuario de ejecución solo necesita leerlo.
COPY app/ ./app/

USER 10001:10001

EXPOSE 8080

CMD ["python", "-m", "app.main"]
