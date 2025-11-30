from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class LocationBase(BaseModel):
    room: str
    area: str
    shelf_box: str
    notes: Optional[str] = None

class LocationCreate(LocationBase):
    pass

class LocationUpdate(BaseModel):
    room: Optional[str] = None
    area: Optional[str] = None
    shelf_box: Optional[str] = None
    notes: Optional[str] = None

class Location(LocationBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
