"""Admin-facing connector endpoints (currently only Microsoft To Do).

OAuth flow:
  1. Mobile app calls GET /connectors/microsoft-todo/auth-url (admin auth).
     Backend returns the Microsoft consent URL with a signed `state` JWT
     binding the warehouse_id + user_id.
  2. Mobile opens that URL in a browser. User signs in to Microsoft.
  3. Microsoft redirects to GET /auth/microsoft/callback?code=...&state=...
     (no Bearer auth — relies on the signed state).
  4. Backend exchanges the code, upserts the connector row, then redirects to
     the app deep link `pantrykeeper://connector/microsoft-todo/done?status=ok`.
"""
from __future__ import annotations

from datetime import datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from fastapi.responses import RedirectResponse
from jose import jwt, JWTError
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.api import deps
from app.core import security
from app.core.config import settings
from app.core.time import utc_now
from app.integrations.microsoft_todo import client as graph
from app.integrations.microsoft_todo import sync as ms_sync
from app.integrations.microsoft_todo.tokens import (
    MicrosoftAuthError,
    build_authorization_url,
    exchange_code_for_tokens,
    get_valid_access_token,
    persist_token_response,
)
from app.models.connector import WarehouseConnector
from app.models.warehouse_member import WarehouseMember
from app.schemas.connector import (
    ConnectorListUpdate,
    ConnectorOut,
    MicrosoftAuthUrlOut,
    MicrosoftListOut,
    MicrosoftListsOut,
)

router = APIRouter()

CONNECTOR_STATE_AUD = "ms-todo-oauth-state"
STATE_TTL_SECONDS = 600  # user has 10min to complete the consent flow


def _require_admin(member: WarehouseMember) -> None:
    if member.role != "admin":
        raise HTTPException(status_code=403, detail="Admin role required")


def _ensure_enabled() -> None:
    if not settings.microsoft_connector_enabled:
        raise HTTPException(
            status_code=503,
            detail="Microsoft connector is not configured on the server",
        )


def _encode_state(warehouse_id: int, user_id: int) -> str:
    payload = {
        "aud": CONNECTOR_STATE_AUD,
        "wh": warehouse_id,
        "uid": user_id,
        "exp": (utc_now() + timedelta(seconds=STATE_TTL_SECONDS)).timestamp(),
    }
    return jwt.encode(payload, security.SECRET_KEY, algorithm=security.ALGORITHM)


def _decode_state(state: str) -> tuple[int, int]:
    try:
        payload = jwt.decode(
            state,
            security.SECRET_KEY,
            algorithms=[security.ALGORITHM],
            audience=CONNECTOR_STATE_AUD,
        )
    except JWTError as e:
        raise HTTPException(status_code=400, detail=f"Invalid OAuth state: {e}")
    return int(payload["wh"]), int(payload["uid"])


def _get_microsoft_connector(db: Session, warehouse_id: int) -> Optional[WarehouseConnector]:
    return (
        db.query(WarehouseConnector)
        .filter(
            WarehouseConnector.warehouse_id == warehouse_id,
            WarehouseConnector.kind == "microsoft_todo",
        )
        .first()
    )


@router.get("/", response_model=List[ConnectorOut])
def list_connectors(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    _require_admin(current_member)
    rows = (
        db.query(WarehouseConnector)
        .filter(WarehouseConnector.warehouse_id == current_member.warehouse_id)
        .all()
    )
    return rows


@router.get("/microsoft-todo", response_model=Optional[ConnectorOut])
def get_microsoft_connector(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    _require_admin(current_member)
    return _get_microsoft_connector(db, current_member.warehouse_id)


@router.get("/microsoft-todo/auth-url", response_model=MicrosoftAuthUrlOut)
def get_microsoft_auth_url(
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    _require_admin(current_member)
    _ensure_enabled()
    state = _encode_state(current_member.warehouse_id, current_member.user_id)
    auth_url = build_authorization_url(state)
    return MicrosoftAuthUrlOut(auth_url=auth_url, state=state)


@router.get("/microsoft-todo/lists", response_model=MicrosoftListsOut)
def get_microsoft_lists(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    _require_admin(current_member)
    _ensure_enabled()
    connector = _get_microsoft_connector(db, current_member.warehouse_id)
    if connector is None or connector.status != "connected":
        raise HTTPException(status_code=400, detail="Microsoft account not connected")
    try:
        access_token = get_valid_access_token(db, connector)
        raw = graph.list_todo_lists(access_token)
    except (MicrosoftAuthError, graph.MicrosoftGraphError) as e:
        raise HTTPException(status_code=502, detail=f"Microsoft Graph error: {e}")
    lists = [
        MicrosoftListOut(
            id=item["id"],
            display_name=item.get("displayName", "(unnamed)"),
            is_owner=item.get("isOwner"),
            well_known_list_name=item.get("wellknownListName"),
        )
        for item in raw
    ]
    return MicrosoftListsOut(lists=lists)


@router.patch("/microsoft-todo", response_model=ConnectorOut)
def update_microsoft_connector(
    payload: ConnectorListUpdate,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    _require_admin(current_member)
    connector = _get_microsoft_connector(db, current_member.warehouse_id)
    if connector is None:
        raise HTTPException(status_code=400, detail="Microsoft account not connected")
    connector.selected_list_id = payload.list_id
    connector.selected_list_name = payload.list_name
    db.add(connector)
    db.commit()
    db.refresh(connector)
    return connector


@router.post("/microsoft-todo/sync-now")
def sync_microsoft_now(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    """Run a poll + push immediately so admins don't have to wait for the
    next scheduled tick to see new tasks in MS To Do or new reminders surface.
    """
    _require_admin(current_member)
    connector = _get_microsoft_connector(db, current_member.warehouse_id)
    if connector is None or connector.status != "connected":
        raise HTTPException(status_code=400, detail="Microsoft account not connected")
    if not connector.selected_list_id:
        raise HTTPException(status_code=400, detail="No list selected")
    transitioned = ms_sync.poll_completed_tasks(db, connector)
    pushed = ms_sync.push_low_stock_to_todo(db, connector)
    return {"pushed": pushed, "transitioned": transitioned}


@router.delete("/microsoft-todo", status_code=204)
def disconnect_microsoft_connector(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    _require_admin(current_member)
    connector = _get_microsoft_connector(db, current_member.warehouse_id)
    if connector is not None:
        db.delete(connector)
        db.commit()
    return Response(status_code=204)


# OAuth callback router — mounted at root, separate from /connectors so the
# URL matches what was registered in the Entra portal.
oauth_router = APIRouter()


@oauth_router.get("/auth/microsoft/callback", include_in_schema=False)
def microsoft_callback(
    code: Optional[str] = Query(default=None),
    state: Optional[str] = Query(default=None),
    error: Optional[str] = Query(default=None),
    error_description: Optional[str] = Query(default=None),
    db: Session = Depends(deps.get_db),
):
    deep_link = f"{settings.APP_DEEP_LINK_SCHEME}://connector/microsoft-todo/done"
    if error:
        return RedirectResponse(
            url=f"{deep_link}?status=error&error={error}",
            status_code=302,
        )
    if not code or not state:
        return RedirectResponse(
            url=f"{deep_link}?status=error&error=missing_params",
            status_code=302,
        )

    warehouse_id, _user_id = _decode_state(state)
    try:
        token_response = exchange_code_for_tokens(code)
    except MicrosoftAuthError as e:
        return RedirectResponse(
            url=f"{deep_link}?status=error&error={e}", status_code=302
        )

    connector = _get_microsoft_connector(db, warehouse_id)
    if connector is None:
        connector = WarehouseConnector(
            warehouse_id=warehouse_id,
            kind="microsoft_todo",
        )
    persist_token_response(connector, token_response)
    db.add(connector)
    db.commit()
    return RedirectResponse(url=f"{deep_link}?status=ok", status_code=302)
