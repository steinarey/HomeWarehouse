from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class UserBase(BaseModel):
    name: str
    role: str = "editor"

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    name: Optional[str] = None
    role: Optional[str] = None

class User(UserBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
