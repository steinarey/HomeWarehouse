from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.user import User
from app.models.warehouse import Warehouse
from app.models.warehouse_member import WarehouseMember
from app.models.invite import Invite
from app.models.product import Product

def get_auth_header(client: TestClient, username: str, password: str) -> dict:
    response = client.post(
        "/login/access-token",
        data={"username": username, "password": password},
    )
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

def test_create_user_and_warehouse(client: TestClient, override_get_db):
    # Register new user
    response = client.post(
        "/users/",
        json={"name": "user_a", "password": "password123", "role": "user"},
    )
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "user_a"
    
    # Login
    headers = get_auth_header(client, "user_a", "password123")
    
    # Check membership
    response = client.get("/users/members/list", headers=headers)
    assert response.status_code == 200
    members = response.json()
    assert len(members) == 1
    assert members[0]["name"] == "user_a"
    assert members[0]["role"] == "admin" # Creator is admin of their own warehouse

def test_invite_flow(client: TestClient, override_get_db, db: Session):
    # 1. User A creates warehouse
    client.post("/users/", json={"name": "admin_user", "password": "password123", "role": "user"})
    headers_a = get_auth_header(client, "admin_user", "password123")
    
    # 2. User A creates invite
    response = client.post("/invites/", json={"role": "user"}, headers=headers_a)
    assert response.status_code == 200
    invite_code = response.json()["code"]
    
    # 3. User B registers with invite code
    response = client.post(
        "/users/",
        json={"name": "invited_user", "password": "password123", "role": "user", "invite_code": invite_code},
    )
    assert response.status_code == 200
    
    # 4. Verify User B is in User A's warehouse
    headers_b = get_auth_header(client, "invited_user", "password123")
    response = client.get("/users/members/list", headers=headers_b)
    assert response.status_code == 200
    members = response.json()
    member_names = [m["name"] for m in members]
    assert "admin_user" in member_names
    assert "invited_user" in member_names

def test_data_isolation(client: TestClient, override_get_db, db: Session):
    # User A (Warehouse A)
    client.post("/users/", json={"name": "iso_user_a", "password": "password123", "role": "user"})
    headers_a = get_auth_header(client, "iso_user_a", "password123")
    
    # User B (Warehouse B)
    client.post("/users/", json={"name": "iso_user_b", "password": "password123", "role": "user"})
    headers_b = get_auth_header(client, "iso_user_b", "password123")
    
    # User A creates product
    # First create category
    cat_response = client.post("/categories/", json={"name": "Cat A"}, headers=headers_a)
    assert cat_response.status_code == 200
    cat_id = cat_response.json()["id"]
    
    prod_response = client.post(
        "/products/",
        json={"name": "Product A", "barcode": "12345", "category_id": cat_id},
        headers=headers_a
    )
    assert prod_response.status_code == 200
    
    # User B tries to list products
    response = client.get("/products/", headers=headers_b)
    assert response.status_code == 200
    products = response.json()
    assert len(products) == 0 # Should not see User A's product
    
    # User A sees product
    response = client.get("/products/", headers=headers_a)
    assert response.status_code == 200
    products = response.json()
    assert len(products) == 1
    assert products[0]["name"] == "Product A"
