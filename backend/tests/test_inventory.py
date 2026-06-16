from fastapi.testclient import TestClient
from sqlalchemy.orm import Session


def get_auth_header(client: TestClient, username: str, password: str) -> dict:
    response = client.post(
        "/login/access-token",
        data={"username": username, "password": password},
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_inventory_flow(client: TestClient, db: Session, override_get_db):
    # Register a user — this auto-creates a warehouse with the user as admin.
    client.post(
        "/users/",
        json={"name": "inv_user", "password": "password123", "role": "user"},
    )
    headers = get_auth_header(client, "inv_user", "password123")

    # Set up scoped fixtures via the API so warehouse_id is populated correctly.
    cat_resp = client.post(
        "/categories/",
        json={"name": "Test Cat", "min_stock": 5},
        headers=headers,
    )
    assert cat_resp.status_code == 200
    cat_id = cat_resp.json()["id"]

    loc_resp = client.post(
        "/locations/",
        json={"room": "Test Room", "area": "Test Area", "shelf_box": "Box 1"},
        headers=headers,
    )
    assert loc_resp.status_code == 200
    loc_id = loc_resp.json()["id"]

    prod_resp = client.post(
        "/products/",
        json={"name": "Test Product", "category_id": cat_id, "package_size": 2},
        headers=headers,
    )
    assert prod_resp.status_code == 200
    product_id = prod_resp.json()["id"]

    # 1. Restock
    response = client.post(
        "/inventory/restock",
        json={
            "product_id": product_id,
            "quantity_packages": 5,  # 10 units
            "location_id": loc_id,
        },
        headers=headers,
    )
    assert response.status_code == 200, response.text
    data = response.json()
    assert data["quantity_delta"] == 10
    assert data["new_quantity"] == 10

    # 2. Consume
    response = client.post(
        "/inventory/consume",
        json={"product_id": product_id, "quantity_units": 3},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    consume_data = response.json()
    assert consume_data["quantity_delta"] == -3
    assert consume_data["new_quantity"] == 7
    consume_action_id = consume_data["id"]

    # 3. Summary
    response = client.get("/inventory/summary", headers=headers)
    assert response.status_code == 200
    summary = response.json()
    assert len(summary) == 1
    assert summary[0]["current_stock"] == 7
    assert summary[0]["is_below_min"] is False  # 7 > 5

    # 4. Adjust — set total to 4 (below min). Validates that the
    #    previously-buggy double-delta path is fixed.
    response = client.post(
        "/inventory/adjust",
        json={"product_id": product_id, "new_total_quantity": 4},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    adjust_data = response.json()
    assert adjust_data["new_quantity"] == 4
    assert adjust_data["quantity_delta"] == -3

    # 5. Adjust upward to 9 — exercises the positive-delta branch.
    response = client.post(
        "/inventory/adjust",
        json={"product_id": product_id, "new_total_quantity": 9},
        headers=headers,
    )
    assert response.status_code == 200, response.text
    assert response.json()["new_quantity"] == 9
    assert response.json()["quantity_delta"] == 5

    # 6. Undo the original consume (current=9, delta reverses to +3 => 12).
    response = client.post(
        f"/inventory/undo/{consume_action_id}", headers=headers
    )
    assert response.status_code == 200, response.text
    undo_data = response.json()
    assert undo_data["action_type"] == "undo"
    assert undo_data["quantity_delta"] == 3
    assert undo_data["new_quantity"] == 12


def test_inventory_cross_warehouse_rejected(client: TestClient, override_get_db):
    """A user must not be able to mutate stock in a warehouse they don't belong to."""
    client.post(
        "/users/",
        json={"name": "owner", "password": "password123", "role": "user"},
    )
    owner_headers = get_auth_header(client, "owner", "password123")

    client.post(
        "/users/",
        json={"name": "stranger", "password": "password123", "role": "user"},
    )
    stranger_headers = get_auth_header(client, "stranger", "password123")

    # Owner creates a product in their warehouse.
    cat_id = client.post(
        "/categories/",
        json={"name": "Owner Cat", "min_stock": 1},
        headers=owner_headers,
    ).json()["id"]
    product_id = client.post(
        "/products/",
        json={"name": "Owner Product", "category_id": cat_id},
        headers=owner_headers,
    ).json()["id"]

    # Stranger tries to restock owner's product using their own token. The
    # service should reject because product.warehouse_id != stranger's warehouse.
    response = client.post(
        "/inventory/restock",
        json={"product_id": product_id, "quantity_packages": 1},
        headers=stranger_headers,
    )
    assert response.status_code == 400
    assert "Product not found" in response.json()["detail"]
