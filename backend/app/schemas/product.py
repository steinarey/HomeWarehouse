from typing import Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

class ProductBase(BaseModel):
    name: str
    category_id: int
    barcode: Optional[str] = None
    package_size: int = 1
    photo_url: Optional[str] = None
    product_metadata: Optional[Dict[str, Any]] = None

class ProductCreate(ProductBase):
    pass

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    category_id: Optional[int] = None
    barcode: Optional[str] = None
    package_size: Optional[int] = None
    photo_url: Optional[str] = None
    product_metadata: Optional[Dict[str, Any]] = None

class Product(ProductBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class ProductByBarcodeRequest(BaseModel):
    barcode: str
