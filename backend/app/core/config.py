import os
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql+psycopg2://inventory_user:password@localhost:5432/inventory")

    # No default — boot fails fast if JWT_SECRET_KEY env var is missing.
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    # 7 days. Mobile UX trade-off until a refresh-token flow lands.
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7

    # External base URL the backend is reachable at — used to build OAuth
    # redirect URIs and any other absolute links Microsoft / clients need.
    PUBLIC_BASE_URL: str = "https://warehouse.steinarey.is"

    # Deep-link scheme used when redirecting users back into the mobile app
    # after the Microsoft OAuth dance completes on the backend.
    APP_DEEP_LINK_SCHEME: str = "pantrykeeper"

    # Microsoft / Microsoft Graph (To Do) connector. Empty client_id disables
    # the connector at runtime (endpoints return 503).
    MICROSOFT_CLIENT_ID: str = ""
    MICROSOFT_CLIENT_SECRET: str = ""
    # `common` accepts personal MSAs (where consumer To Do lives) and work/school accounts.
    MICROSOFT_AUTHORITY: str = "https://login.microsoftonline.com/common"
    MICROSOFT_SCOPES: str = "Tasks.ReadWrite User.Read offline_access"

    # Fernet key (URL-safe base64, 32 bytes) used to encrypt OAuth tokens at
    # rest. Generate with `python -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())"`.
    # Empty disables the connector (endpoints return 503).
    CONNECTOR_ENCRYPTION_KEY: str = ""

    # Background sync cadence for Microsoft To Do, in seconds.
    MS_TODO_SYNC_INTERVAL_SECONDS: int = 600

    model_config = SettingsConfigDict(case_sensitive=True)

    @property
    def microsoft_redirect_uri(self) -> str:
        return f"{self.PUBLIC_BASE_URL.rstrip('/')}/auth/microsoft/callback"

    @property
    def microsoft_scope_list(self) -> list[str]:
        return [s for s in self.MICROSOFT_SCOPES.split() if s]

    @property
    def microsoft_connector_enabled(self) -> bool:
        return bool(self.MICROSOFT_CLIENT_ID and self.MICROSOFT_CLIENT_SECRET and self.CONNECTOR_ENCRYPTION_KEY)


settings = Settings()
