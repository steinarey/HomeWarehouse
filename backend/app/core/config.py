import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+psycopg2://inventory_user:password@localhost:5432/inventory")

    class Config:
        case_sensitive = True

settings = Settings()
