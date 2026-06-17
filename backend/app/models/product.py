from datetime import datetime
from typing import Optional, Any
from sqlalchemy import String, Integer, ForeignKey, DateTime, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.time import utc_now
from app.db.base import Base

class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String, nullable=False)
    category_id: Mapped[int] = mapped_column(ForeignKey("categories.id"), nullable=False)
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    barcode: Mapped[Optional[str]] = mapped_column(String, nullable=True) # Removed unique=True to allow same barcode in different warehouses, will handle uniqueness in logic or composite index
    package_size: Mapped[int] = mapped_column(Integer, default=1)
    photo_url: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    product_metadata: Mapped[Optional[dict[str, Any]]] = mapped_column(JSON, nullable=True)
    location_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("locations.id", ondelete="SET NULL"),
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now)

    category = relationship("Category", back_populates="products")
    warehouse = relationship("Warehouse")
    stock_batches = relationship(
        "StockBatch",
        cascade="all, delete-orphan",
        passive_deletes=False,
    )
