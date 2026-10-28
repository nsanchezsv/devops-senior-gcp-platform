import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "healthy"}


@pytest.mark.parametrize(
    "numero, estado",
    [
        ("TR-001", "recibido"),
        ("TR-002", "en_proceso"),
        ("TR-003", "completado"),
    ],
)
def test_tramite_existente(numero, estado):
    response = client.get(f"/tramites/{numero}")
    assert response.status_code == 200
    body = response.json()
    assert body["numero"] == numero
    assert body["estado"] == estado
    assert body["mensaje"]
    assert set(body) == {"numero", "estado", "mensaje"}


def test_tramite_no_existe():
    response = client.get("/tramites/TR-999")
    assert response.status_code == 404
    assert response.json() == {"detail": "Trámite no encontrado"}


def test_tramite_numero_invalido():
    response = client.get("/tramites/TR_001!")
    assert response.status_code == 422


def test_api_key_no_se_expone(monkeypatch, caplog):
    import importlib

    import app.main as main

    original = main.API_KEY
    monkeypatch.setenv("API_KEY", "valor-de-prueba")
    modulo = importlib.reload(main)
    try:
        assert modulo.API_KEY.get_secret_value() == "valor-de-prueba"
        assert "valor-de-prueba" not in repr(modulo.API_KEY)
        with TestClient(modulo.app) as test_client:
            for path in ("/health", "/tramites/TR-001", "/tramites/X", "/tramites/invalid_", "/openapi.json"):
                respuesta = test_client.get(path)
                assert "valor-de-prueba" not in respuesta.text
        assert "valor-de-prueba" not in caplog.text
    finally:
        main.API_KEY = original


def test_tramite_minusculas():
    response = client.get("/tramites/tr-001")
    assert response.status_code == 200
    assert response.json()["numero"] == "TR-001"
