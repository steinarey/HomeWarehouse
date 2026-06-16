from datetime import datetime
from typing import Optional  # noqa: F401 (used in Invite below)
from pydantic import BaseModel, ConfigDict

class InviteBase(BaseModel):
    role: str = "user"

class InviteCreate(InviteBase):
    max_uses: Optional[int] = None

class Invite(InviteBase):
    id: int
    code: str
    warehouse_id: int
    created_by_user_id: int
    expires_at: datetime
    created_at: datetime
    max_uses: Optional[int] = None
    uses: int = 0
    revoked: bool = False

    model_config = ConfigDict(from_attributes=True)
