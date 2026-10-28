"""API mínima del Ministerio de Trámites Ciudadanos."""

import os
from enum import Enum

import uvicorn
from fastapi import FastAPI, HTTPException, Path
from pydantic import BaseModel, SecretStr

# API_KEY se lee desde el entorno (en Cloud Run se inyectará desde Secret Manager).
# SecretStr oculta el valor en repr; no registrar ni devolver get_secret_value().
API_KEY = SecretStr(os.getenv("API_KEY", ""))


class EstadoTramite(str, Enum):
    recibido = "recibido"
    en_proceso = "en_proceso"
    completado = "completado"


class HealthResponse(BaseModel):
    status: str


class TramiteResponse(BaseModel):
    numero: str
    estado: EstadoTramite
    mensaje: str


# Datos simulados en memoria.
TRAMITES: dict[str, TramiteResponse] = {
    "TR-001": TramiteResponse(
        numero="TR-001",
        estado=EstadoTramite.recibido,
        mensaje="Su trámite fue recibido y está pendiente de revisión.",
    ),
    "TR-002": TramiteResponse(
        numero="TR-002",
        estado=EstadoTramite.en_proceso,
        mensaje="Su trámite está siendo procesado.",
    ),
    "TR-003": TramiteResponse(
        numero="TR-003",
        estado=EstadoTramite.completado,
        mensaje="Su trámite fue completado.",
    ),
}

app = FastAPI(title="Ministerio de Trámites Ciudadanos")


@app.get("/health", response_model=HealthResponse)
def health() -> HealthResponse:
    return HealthResponse(status="healthy")


@app.get("/tramites/{numero}", response_model=TramiteResponse)
def obtener_tramite(
    numero: str = Path(min_length=1, max_length=20, pattern=r"^[A-Za-z0-9-]+$"),
) -> TramiteResponse:
    tramite = TRAMITES.get(numero.upper())
    if tramite is None:
        raise HTTPException(status_code=404, detail="Trámite no encontrado")
    return tramite


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
