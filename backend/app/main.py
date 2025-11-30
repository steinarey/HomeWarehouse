from fastapi import FastAPI

from app.api.api import api_router

app = FastAPI(title="Home Inventory API", version="0.1.0")

app.include_router(api_router)

@app.get("/health")
def health_check():
    return {"status": "ok"}
