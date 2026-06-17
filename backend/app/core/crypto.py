"""Symmetric-encryption helpers for connector token storage.

We use Fernet (AES-128-CBC + HMAC-SHA-256) keyed off CONNECTOR_ENCRYPTION_KEY.
Tokens are encrypted before being written to Postgres so a DB dump alone does
not yield usable Microsoft refresh tokens.
"""
from functools import lru_cache
from typing import Optional

from cryptography.fernet import Fernet, InvalidToken

from app.core.config import settings


@lru_cache(maxsize=1)
def _fernet() -> Fernet:
    if not settings.CONNECTOR_ENCRYPTION_KEY:
        raise RuntimeError("CONNECTOR_ENCRYPTION_KEY is not configured")
    return Fernet(settings.CONNECTOR_ENCRYPTION_KEY.encode())


def encrypt(plaintext: Optional[str]) -> Optional[str]:
    if plaintext is None:
        return None
    return _fernet().encrypt(plaintext.encode()).decode()


def decrypt(ciphertext: Optional[str]) -> Optional[str]:
    if ciphertext is None:
        return None
    try:
        return _fernet().decrypt(ciphertext.encode()).decode()
    except InvalidToken as e:
        raise RuntimeError("Unable to decrypt connector token — wrong CONNECTOR_ENCRYPTION_KEY?") from e
