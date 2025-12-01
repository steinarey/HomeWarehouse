from datetime import datetime
from typing import Optional, Any
from sqlalchemy import String, Integer, ForeignKey, DateTime, Boolean, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class InventoryAction(Base):
    __tablename__ = "inventory_actions"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    user_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), nullable=True)
    action_type: Mapped[str] = mapped_column(String, nullable=False) # consume, restock, edit
    source: Mapped[Optional[str]] = mapped_column(String, nullable=True) # barcode, nfc, manual, api
    product_id: Mapped[Optional[int]] = mapped_column(ForeignKey("products.id"), nullable=True)
    category_id: Mapped[Optional[int]] = mapped_column(ForeignKey("categories.id"), nullable=True)
    stock_batch_id: Mapped[Optional[int]] = mapped_column(ForeignKey("stock_batches.id"), nullable=True)
    quantity_delta: Mapped[int] = mapped_column(Integer, nullable=False)
    previous_quantity: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    new_quantity: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    payload: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    undone: Mapped[bool] = mapped_column(Boolean, default=False)
    undone_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    undone_by_id: Mapped[Optional[int]] = mapped_column(ForeignKey("users.id"), nullable=True)

    user = relationship("User", foreign_keys=[user_id])
    warehouse = relationship("Warehouse")
    product = relationship("Product")
    category = relationship("Category")
    stock_batch = relationship("StockBatch")
    undone_by = relationship("User", foreign_keys=[undone_by_id])
