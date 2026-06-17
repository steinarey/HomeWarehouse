"""Pending-restock reminders surfaced on the mobile dashboard.

A row in PendingRestock with `status='awaiting_restock'` is something the user
ticked off in their external integration (currently Microsoft To Do) and now
needs to update PantryKeeper stock for. The dashboard pulls these to nudge the
user. Resolving happens either via the inventory mutation hook
(automatic — preferred) or via the explicit dismiss endpoint below.
"""
from __future__ import annotations

from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.api import deps
from app.core.time import utc_now
from app.models.category import Category
from app.models.pending_restock import (
    STATUS_AWAITING_RESTOCK,
    STATUS_RESOLVED,
    PendingRestock,
)
from app.models.product import Product
from app.models.stock_batch import StockBatch
from app.models.warehouse_member import WarehouseMember
from app.schemas.pending_restock import PendingRestockOut

router = APIRouter()


def _current_stocks(db: Session, warehouse_id: int) -> dict[int, int]:
    rows = (
        db.query(Product.category_id, func.coalesce(func.sum(StockBatch.quantity), 0))
        .join(StockBatch, StockBatch.product_id == Product.id)
        .filter(Product.warehouse_id == warehouse_id)
        .group_by(Product.category_id)
        .all()
    )
    return {cat_id: int(total) for cat_id, total in rows}


@router.get("/", response_model=List[PendingRestockOut])
def list_pending_restocks(
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    """Open reminders for this warehouse that the user needs to act on."""
    rows = (
        db.query(PendingRestock, Category)
        .join(Category, Category.id == PendingRestock.category_id)
        .filter(
            PendingRestock.warehouse_id == current_member.warehouse_id,
            PendingRestock.status == STATUS_AWAITING_RESTOCK,
        )
        .order_by(PendingRestock.created_at.desc())
        .all()
    )
    stocks = _current_stocks(db, current_member.warehouse_id)
    return [
        PendingRestockOut(
            id=row.id,
            category_id=row.category_id,
            category_name=cat.name,
            source=row.source,
            status=row.status,
            external_task_id=row.external_task_id,
            current_stock=stocks.get(row.category_id, 0),
            min_stock=cat.min_stock,
            created_at=row.created_at,
            updated_at=row.updated_at,
        )
        for row, cat in rows
    ]


@router.post("/{pending_id}/dismiss", response_model=PendingRestockOut)
def dismiss_pending_restock(
    pending_id: int,
    db: Session = Depends(deps.get_db),
    current_member: WarehouseMember = Depends(deps.get_current_warehouse_member),
):
    row = (
        db.query(PendingRestock)
        .filter(
            PendingRestock.id == pending_id,
            PendingRestock.warehouse_id == current_member.warehouse_id,
        )
        .first()
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Pending restock not found")

    row.status = STATUS_RESOLVED
    row.resolved_at = utc_now()
    row.resolved_reason = "user_dismissed"
    db.add(row)
    db.commit()
    db.refresh(row)

    category = db.query(Category).filter(Category.id == row.category_id).first()
    stocks = _current_stocks(db, current_member.warehouse_id)
    return PendingRestockOut(
        id=row.id,
        category_id=row.category_id,
        category_name=category.name if category else "?",
        source=row.source,
        status=row.status,
        external_task_id=row.external_task_id,
        current_stock=stocks.get(row.category_id, 0),
        min_stock=category.min_stock if category else 0,
        created_at=row.created_at,
        updated_at=row.updated_at,
    )
