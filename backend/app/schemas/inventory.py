from typing import Optional, Any, Dict, List
from pydantic import BaseModel
from datetime import date, datetime

class RestockRequest(BaseModel):
    product_id: int
    quantity_packages: int
    location_id: Optional[int] = None
    expiry_date: Optional[date] = None
    user_id: Optional[int] = None
    source: str = "api"

class ConsumeRequest(BaseModel):
    product_id: int
    quantity_units: int
    location_id: Optional[int] = None
    user_id: Optional[int] = None
    source: str = "api"

class AdjustRequest(BaseModel):
    product_id: int
    new_total_quantity: int
    user_id: Optional[int] = None
    reason: str = "manual_correction"

class InventoryAction(BaseModel):
    id: int
    user_id: Optional[int] = None
    action_type: str
    source: Optional[str] = None
    product_id: Optional[int] = None
    category_id: Optional[int] = None
    stock_batch_id: Optional[int] = None
    quantity_delta: int
    previous_quantity: Optional[int] = None
    new_quantity: Optional[int] = None
    payload: Optional[Dict[str, Any]] = None
    created_at: datetime
    undone: bool
    undone_at: Optional[datetime] = None
    undone_by_id: Optional[int] = None

    class Config:
        from_attributes = True

class CategorySummary(BaseModel):
    category_id: int
    name: str
    is_critical: bool
    is_one_off: bool
    min_stock: int
    target_stock: Optional[int] = None
    current_stock: int
    is_below_min: bool

class LowStockItem(BaseModel):
    category_id: int
    name: str
    current_stock: int
    min_stock: int
    target_stock: Optional[int] = None
    recommended_buy_quantity: int
    is_critical: bool

class DashboardSummary(BaseModel):
    total_categories: int
    low_stock_categories: int
    low_stock_critical_categories: int
    recent_actions: List[Dict[str, Any]]
