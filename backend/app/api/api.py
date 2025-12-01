from fastapi import APIRouter
from app.api.endpoints import users, locations, categories, products, inventory, login, invites

api_router = APIRouter()
api_router.include_router(login.router, tags=["login"])
api_router.include_router(users.router, prefix="/users", tags=["users"])
api_router.include_router(locations.router, prefix="/locations", tags=["locations"])
api_router.include_router(categories.router, prefix="/categories", tags=["categories"])
api_router.include_router(products.router, prefix="/products", tags=["products"])
api_router.include_router(inventory.router, prefix="/inventory", tags=["inventory"])
api_router.include_router(inventory.router, prefix="", tags=["dashboard"]) # For /dashboard
api_router.include_router(invites.router, prefix="/invites", tags=["invites"])
