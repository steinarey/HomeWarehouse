from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.time import utc_now
from app.db.base import Base


# Lifecycle:
#  awaiting_purchase: we pushed a "buy more X" task to MS To Do; user hasn't
#                     ticked it yet. Row stays open even if category becomes
#                     not-low so we don't double-push if it dips again.
#  awaiting_restock:  user ticked the task in MS To Do. PantryKeeper now needs
#                     a stock update. Surfaces on dashboard.
#  resolved:          user adjusted/restocked the category (any path), or
#                     explicitly dismissed the reminder.
STATUS_AWAITING_PURCHASE = "awaiting_purchase"
STATUS_AWAITING_RESTOCK = "awaiting_restock"
STATUS_RESOLVED = "resolved"


class PendingRestock(Base):
    """An open reminder tied to a category, driven by an external integration.

    See module-level constants for the status lifecycle. There is at most one
    non-resolved row per (warehouse_id, category_id, source); enforcement lives
    in app logic since SQLite (used in tests) does not support partial indexes.
    """

    __tablename__ = "pending_restocks"
    __table_args__ = (
        Index("ix_pending_restocks_warehouse_category", "warehouse_id", "category_id"),
        Index("ix_pending_restocks_status", "status"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"), nullable=False)

    source: Mapped[str] = mapped_column(String, nullable=False)
    status: Mapped[str] = mapped_column(String, nullable=False, default=STATUS_AWAITING_PURCHASE)

    external_task_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    external_list_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    resolved_reason: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    warehouse = relationship("Warehouse")
    category = relationship("Category")
