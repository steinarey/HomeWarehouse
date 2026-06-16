from datetime import datetime
from pydantic import BaseModel, ConfigDict


class WarehouseMemberOut(BaseModel):
    id: int
    name: str
    role: str
    joined_at: datetime

    model_config = ConfigDict(from_attributes=True)
