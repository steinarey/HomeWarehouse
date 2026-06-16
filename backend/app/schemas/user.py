from typing import Optional
from pydantic import BaseModel, ConfigDict
from datetime import datetime

class UserBase(BaseModel):
    name: str
    role: str = "editor"

class UserCreate(UserBase):
    password: str
    invite_code: Optional[str] = None

class UserUpdate(BaseModel):
    name: Optional[str] = None
    role: Optional[str] = None

class User(UserBase):
    id: int
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
