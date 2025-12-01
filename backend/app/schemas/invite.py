from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class InviteBase(BaseModel):
    role: str = "user"

class InviteCreate(InviteBase):
    pass

class Invite(InviteBase):
    id: int
    code: str
    warehouse_id: int
    created_by_user_id: int
    expires_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True
