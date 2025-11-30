from fastapi.testclient import TestClient
from sqlalchemy.orm import Session
from app.models.category import Category
from app.models.product import Product
from app.models.location import Location
from app.models.user import User

def test_inventory_flow(client: TestClient, db: Session, override_get_db):
    # Setup data
    user = User(name="Test User", role="editor")
    location = Location(room="Test Room", area="Test Area", shelf_box="Box 1")
    category = Category(name="Test Cat", min_stock=5)
    db.add_all([user, location, category])
    db.commit()
    
    product = Product(name="Test Product", category_id=category.id, package_size=2)
    db.add(product)
    db.commit()

    # 1. Restock
    response = client.post("/inventory/restock", json={
        "product_id": product.id,
        "quantity_packages": 5, # 10 units
        "location_id": location.id,
        "user_id": user.id
    })
    assert response.status_code == 200
    data = response.json()
    assert data["quantity_delta"] == 10
    assert data["new_quantity"] == 10

    # 2. Consume
    response = client.post("/inventory/consume", json={
        "product_id": product.id,
        "quantity_units": 3,
        "user_id": user.id
    })
    assert response.status_code == 200
    data = response.json()
    assert data["quantity_delta"] == -3
    assert data["new_quantity"] == 7

    # 3. Summary
    response = client.get("/inventory/summary")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["current_stock"] == 7
    assert data[0]["is_below_min"] == False # 7 > 5

    # 4. Undo Consume
    action_id = response.history[0].json().get("id") # Wait, I need the action id from consume response
    # Actually I didn't capture consume response properly in previous step variable 'data'
    # Let's re-fetch actions or use the returned id
    consume_action_id = data["id"] # The consume response returns the action

    response = client.post(f"/inventory/undo/{consume_action_id}?user_id={user.id}")
    assert response.status_code == 200
    data = response.json()
    assert data["action_type"] == "undo"
    assert data["quantity_delta"] == 3
    assert data["new_quantity"] == 10
