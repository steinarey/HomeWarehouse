from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, ConfigDict


class ConnectorOut(BaseModel):
    """Connector status exposed to the admin UI. Secrets are never included."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    kind: str
    status: str
    ms_user_email: Optional[str] = None
    selected_list_id: Optional[str] = None
    selected_list_name: Optional[str] = None
    last_synced_at: Optional[datetime] = None
    last_error: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class ConnectorListUpdate(BaseModel):
    list_id: str
    list_name: Optional[str] = None


class MicrosoftAuthUrlOut(BaseModel):
    auth_url: str
    state: str


class MicrosoftListOut(BaseModel):
    id: str
    display_name: str
    is_owner: Optional[bool] = None
    well_known_list_name: Optional[str] = None


class MicrosoftListsOut(BaseModel):
    lists: List[MicrosoftListOut]
