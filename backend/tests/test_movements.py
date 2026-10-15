def seed(client, sample_product):
    return client.post("/api/products", json=sample_product).json()["id"]


def test_stock_in_increases_quantity(client, sample_product):
    product_id = seed(client, sample_product)
    response = client.post(
        f"/api/products/{product_id}/movements",
        json={"movement_type": "IN", "quantity": 10, "note": "Supplier delivery"},
    )
    assert response.status_code == 201
    assert response.json()["movement_type"] == "IN"
    assert client.get(f"/api/products/{product_id}").json()["quantity"] == 35


def test_stock_out_decreases_quantity(client, sample_product):
    product_id = seed(client, sample_product)
    response = client.post(
        f"/api/products/{product_id}/movements", json={"movement_type": "OUT", "quantity": 5}
    )
    assert response.status_code == 201
    assert client.get(f"/api/products/{product_id}").json()["quantity"] == 20


def test_stock_out_cannot_exceed_available(client, sample_product):
    product_id = seed(client, sample_product)
    response = client.post(
        f"/api/products/{product_id}/movements", json={"movement_type": "OUT", "quantity": 999}
    )
    assert response.status_code == 400
    assert "Insufficient stock" in response.json()["detail"]
    assert client.get(f"/api/products/{product_id}").json()["quantity"] == 25


def test_movement_for_unknown_product_returns_404(client):
    response = client.post(
        "/api/products/4242/movements", json={"movement_type": "IN", "quantity": 1}
    )
    assert response.status_code == 404


def test_list_movements_newest_first(client, sample_product):
    product_id = seed(client, sample_product)
    url = f"/api/products/{product_id}/movements"
    client.post(url, json={"movement_type": "IN", "quantity": 1})
    client.post(url, json={"movement_type": "OUT", "quantity": 2})
    response = client.get("/api/movements", params={"limit": 10})
    assert response.status_code == 200
    body = response.json()
    assert [m["movement_type"] for m in body] == ["OUT", "IN"]
    assert body[0]["product_sku"] == "LAP-001"
