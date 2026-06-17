"""Microsoft OAuth + token-refresh helpers.

Wraps `msal.ConfidentialClientApplication` so callers get a fresh access token
without having to think about refresh timing or encryption.
"""
from __future__ import annotations

from datetime import timedelta
from typing import Any, Optional

import msal
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.crypto import decrypt, encrypt
from app.core.time import utc_now
from app.models.connector import WarehouseConnector

GRAPH_BASE = "https://graph.microsoft.com/v1.0"


class MicrosoftAuthError(RuntimeError):
    """Raised when the MS token exchange / refresh fails."""


def _msal_app() -> msal.ConfidentialClientApplication:
    if not settings.microsoft_connector_enabled:
        raise MicrosoftAuthError("Microsoft connector is not configured on the backend")
    return msal.ConfidentialClientApplication(
        client_id=settings.MICROSOFT_CLIENT_ID,
        client_credential=settings.MICROSOFT_CLIENT_SECRET,
        authority=settings.MICROSOFT_AUTHORITY,
    )


def build_authorization_url(state: str) -> str:
    """Return the URL the user should be redirected to to start OAuth."""
    app = _msal_app()
    return app.get_authorization_request_url(
        scopes=settings.microsoft_scope_list,
        state=state,
        redirect_uri=settings.microsoft_redirect_uri,
        prompt="select_account",
    )


def exchange_code_for_tokens(code: str) -> dict[str, Any]:
    """Exchange an authorization code for an access + refresh token."""
    app = _msal_app()
    result = app.acquire_token_by_authorization_code(
        code,
        scopes=settings.microsoft_scope_list,
        redirect_uri=settings.microsoft_redirect_uri,
    )
    if "error" in result:
        raise MicrosoftAuthError(
            f"OAuth code exchange failed: {result.get('error')} — {result.get('error_description')}"
        )
    return result


def _refresh_with_refresh_token(refresh_token: str) -> dict[str, Any]:
    app = _msal_app()
    result = app.acquire_token_by_refresh_token(
        refresh_token,
        scopes=settings.microsoft_scope_list,
    )
    if "error" in result:
        raise MicrosoftAuthError(
            f"Token refresh failed: {result.get('error')} — {result.get('error_description')}"
        )
    return result


def persist_token_response(connector: WarehouseConnector, token_response: dict[str, Any]) -> None:
    """Apply an MSAL token response onto a connector row (encrypts the tokens)."""
    access_token = token_response.get("access_token")
    refresh_token = token_response.get("refresh_token")
    expires_in = int(token_response.get("expires_in", 3600))

    if not access_token:
        raise MicrosoftAuthError("Token response missing access_token")

    connector.access_token_enc = encrypt(access_token)
    # MSAL sometimes omits refresh_token on subsequent refreshes — keep the old
    # one when that happens so we don't lose the long-lived refresh credential.
    if refresh_token:
        connector.refresh_token_enc = encrypt(refresh_token)
    connector.access_token_expires_at = utc_now() + timedelta(seconds=expires_in - 60)
    connector.status = "connected"
    connector.last_error = None

    id_claims = token_response.get("id_token_claims") or {}
    if id_claims.get("preferred_username"):
        connector.ms_user_email = id_claims["preferred_username"]
    if id_claims.get("oid"):
        connector.ms_user_id = id_claims["oid"]


def get_valid_access_token(db: Session, connector: WarehouseConnector) -> str:
    """Return a non-expired access token, refreshing if needed.

    Persists the refresh result to the DB. Caller is responsible for handling
    `MicrosoftAuthError` (typically by marking the connector as `status='error'`).
    """
    expires_at = connector.access_token_expires_at
    if connector.access_token_enc and expires_at and expires_at > utc_now():
        token = decrypt(connector.access_token_enc)
        assert token is not None  # decrypt only returns None when input is None
        return token

    if not connector.refresh_token_enc:
        raise MicrosoftAuthError("No refresh token stored — admin must reconnect")

    refresh_token = decrypt(connector.refresh_token_enc)
    assert refresh_token is not None
    result = _refresh_with_refresh_token(refresh_token)
    persist_token_response(connector, result)
    db.add(connector)
    db.commit()
    db.refresh(connector)
    access_token = decrypt(connector.access_token_enc)
    assert access_token is not None
    return access_token
