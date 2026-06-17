import os
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware

from app.api.api import api_router
from app.core.rate_limit import limiter
from app.core.scheduler import start_scheduler, stop_scheduler


@asynccontextmanager
async def lifespan(app: FastAPI):
    start_scheduler()
    try:
        yield
    finally:
        stop_scheduler()


app = FastAPI(title="Home Inventory API", version="0.1.0", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
app.add_middleware(SlowAPIMiddleware)

# Comma-separated origins via env (e.g. "https://app.example.com,https://staging.example.com").
# Falls back to dev-friendly defaults when unset.
_cors_env = os.getenv("CORS_ALLOW_ORIGINS")
_cors_origins = (
    [o.strip() for o in _cors_env.split(",") if o.strip()]
    if _cors_env
    else ["http://localhost:*", "http://127.0.0.1:*"]
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=_cors_origins if _cors_env else [],
    allow_origin_regex=None if _cors_env else r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(api_router)


@app.get("/health")
def health_check():
    return {"status": "ok"}
