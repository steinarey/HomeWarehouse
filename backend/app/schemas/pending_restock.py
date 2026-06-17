from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict


class PendingRestockOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    category_id: int
    category_name: str
    source: str
    status: str
    external_task_id: Optional[str] = None
    current_stock: int
    min_stock: int
    created_at: datetime
    updated_at: datetime
