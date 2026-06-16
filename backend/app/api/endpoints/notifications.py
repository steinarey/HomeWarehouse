from typing import Any, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, desc

from app import models, schemas
from app.api import deps
from app.core.time import utc_now

router = APIRouter()

@router.get("/pending", response_model=List[schemas.NotificationPending])
def get_pending_notifications(
    db: Session = Depends(deps.get_db),
    current_member: models.WarehouseMember = Depends(deps.get_current_warehouse_member),
) -> Any:
    """
    Get list of categories that are due for restock based on consumption rate.
    """
    # 1. Get all categories with consumption_rate set for this warehouse
    categories = db.query(models.Category).filter(
        models.Category.warehouse_id == current_member.warehouse_id,
        models.Category.consumption_rate.isnot(None),
        models.Category.consumption_rate > 0
    ).all()

    pending_notifications = []

    for category in categories:
        # 2. Find last restock or create action
        last_action = db.query(models.InventoryAction).filter(
            models.InventoryAction.category_id == category.id,
            models.InventoryAction.action_type.in_(["restock", "create", "set"]), # 'set' might be used for initial stock
            models.InventoryAction.undone == False
        ).order_by(desc(models.InventoryAction.created_at)).first()

        last_restock_date = category.created_at
        if last_action:
            last_restock_date = last_action.created_at
        
        # 3. Calculate days elapsed with sub-day precision (.days dropped
        # partial-day deltas — a 23h-old restock looked like 0 days).
        days_elapsed = (utc_now() - last_restock_date).total_seconds() / 86400

        # 4. Check threshold (50%). If consumption_rate is 10 days, warn at 5.
        threshold_days = category.consumption_rate * 0.5
        
        if days_elapsed >= threshold_days:
            pending_notifications.append(
                schemas.NotificationPending(
                    category_id=category.id,
                    category_name=category.name,
                    days_elapsed=days_elapsed,
                    consumption_rate=category.consumption_rate,
                    threshold_days=threshold_days
                )
            )

    return pending_notifications
