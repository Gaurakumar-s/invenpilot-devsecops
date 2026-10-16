def test_root_lists_service_metadata(client):
    response = client.get("/")
    assert response.status_code == 200
    body = response.json()
    assert body["service"] == "InvenPilot API"
    assert body["docs"] == "/docs"


def test_health_returns_up(client):
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "UP"}


def test_ready_checks_database(client):
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "READY"


def test_metrics_exposes_prometheus_format(client):
    client.get("/api/products")  # generate at least one request sample
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "http_requests_total" in response.text
