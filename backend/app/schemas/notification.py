from pydantic import BaseModel

class NotificationPending(BaseModel):
    category_id: int
    category_name: str
    days_elapsed: float
    consumption_rate: int
    threshold_days: float
