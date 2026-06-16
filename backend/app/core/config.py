import os
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+psycopg2://inventory_user:password@localhost:5432/inventory")

    # No default — boot fails fast if JWT_SECRET_KEY env var is missing.
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    # 7 days. Mobile UX trade-off until a refresh-token flow lands.
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7

    model_config = SettingsConfigDict(case_sensitive=True)

settings = Settings()
