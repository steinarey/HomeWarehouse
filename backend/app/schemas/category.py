from typing import Optional
from pydantic import BaseModel
from datetime import datetime

class CategoryBase(BaseModel):
    name: str
    description: Optional[str] = None
    is_critical: bool = False
    is_one_off: bool = False
    min_stock: int = 0
    target_stock: Optional[int] = None
    location_id: Optional[int] = None
    nfc_tag_id: Optional[str] = None

class CategoryCreate(CategoryBase):
    pass

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_critical: Optional[bool] = None
    is_one_off: Optional[bool] = None
    min_stock: Optional[int] = None
    target_stock: Optional[int] = None
    location_id: Optional[int] = None
    nfc_tag_id: Optional[str] = None

class Category(CategoryBase):
    id: int
    created_at: datetime
    updated_at: datetime
    
    # Calculated fields
    current_stock: Optional[int] = None
    is_below_min: Optional[bool] = None

    class Config:
        from_attributes = True
