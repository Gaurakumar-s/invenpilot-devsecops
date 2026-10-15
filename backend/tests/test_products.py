def create(client, payload, **overrides):
    return client.post("/api/products", json={**payload, **overrides})


def test_create_product_returns_201(client, sample_product):
    response = create(client, sample_product)
    assert response.status_code == 201
    body = response.json()
    assert body["sku"] == "LAP-001"
    assert body["quantity"] == 25
    assert body["low_stock"] is False
    assert "id" in body


def test_create_product_rejects_invalid_payload(client, sample_product):
    response = create(client, sample_product, quantity=-1)
    assert response.status_code == 422


def test_create_product_rejects_duplicate_sku(client, sample_product):
    assert create(client, sample_product).status_code == 201
    response = create(client, sample_product)
    assert response.status_code == 409


def test_list_products_returns_all(client, sample_product):
    create(client, sample_product)
    create(client, sample_product, sku="MON-001", name="27-inch Monitor", category="Displays")
    response = client.get("/api/products")
    assert response.status_code == 200
    assert len(response.json()) == 2


def test_list_products_filters_by_category_and_search(client, sample_product):
    create(client, sample_product)
    create(client, sample_product, sku="MON-001", name="27-inch Monitor", category="Displays")
    assert len(client.get("/api/products", params={"category": "Displays"}).json()) == 1
    assert len(client.get("/api/products", params={"search": "latitude"}).json()) == 1


def test_get_product_by_id(client, sample_product):
    product_id = create(client, sample_product).json()["id"]
    response = client.get(f"/api/products/{product_id}")
    assert response.status_code == 200
    assert response.json()["name"] == "Dell Latitude 5540"


def test_get_missing_product_returns_404(client):
    response = client.get("/api/products/9999")
    assert response.status_code == 404
    assert response.json()["detail"] == "Product not found"


def test_update_product(client, sample_product):
    product_id = create(client, sample_product).json()["id"]
    response = client.put(
        f"/api/products/{product_id}", json={"quantity": 3, "unit_price": 799.0}
    )
    assert response.status_code == 200
    body = response.json()
    assert body["quantity"] == 3
    assert body["unit_price"] == 799.0
    assert body["low_stock"] is True  # 3 <= reorder_level 5


def test_delete_product(client, sample_product):
    product_id = create(client, sample_product).json()["id"]
    assert client.delete(f"/api/products/{product_id}").status_code == 204
    assert client.get(f"/api/products/{product_id}").status_code == 404
    assert client.delete(f"/api/products/{product_id}").status_code == 404


def test_stats_aggregates_inventory(client, sample_product):
    create(client, sample_product)  # 25 x 899.99
    create(client, sample_product, sku="KB-001", name="Keyboard", quantity=2, unit_price=20.0)
    create(client, sample_product, sku="MS-001", name="Mouse", quantity=0, unit_price=10.0)
    stats = client.get("/api/products/stats").json()
    assert stats["total_products"] == 3
    assert stats["total_units"] == 27
    assert stats["inventory_value"] == round(25 * 899.99 + 2 * 20.0, 2)
    assert stats["low_stock_count"] == 1
    assert stats["out_of_stock_count"] == 1


def test_low_stock_endpoint(client, sample_product):
    create(client, sample_product)
    create(client, sample_product, sku="KB-001", name="Keyboard", quantity=2)
    response = client.get("/api/products/low-stock")
    assert response.status_code == 200
    assert [p["sku"] for p in response.json()] == ["KB-001"]
