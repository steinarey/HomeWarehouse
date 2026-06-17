from typing import Optional
from pydantic import BaseModel, ConfigDict
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

    model_config = ConfigDict(from_attributes=True)


class LocationBatchOut(BaseModel):
    id: int
    quantity: int
    expiry_date: Optional["date_type"] = None  # forward-ref kept simple via __future__-style note


class LocationProductOut(BaseModel):
    id: int
    name: str
    total_quantity: int
    batches: list[LocationBatchOut]


class LocationCategoryOut(BaseModel):
    id: int
    name: str
    total_quantity: int
    products: list[LocationProductOut]


class LocationContents(BaseModel):
    location: Location
    total_quantity: int
    categories: list[LocationCategoryOut]


# Resolve forward ref for the date type — date import added below to avoid
# rewriting the module header.
from datetime import date as date_type  # noqa: E402

LocationBatchOut.model_rebuild()
