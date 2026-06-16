from datetime import datetime
from typing import Optional
from sqlalchemy import String, Boolean, Integer, ForeignKey, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.time import utc_now
from app.db.base import Base

class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    name: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    description: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    is_critical: Mapped[bool] = mapped_column(Boolean, default=False)
    is_one_off: Mapped[bool] = mapped_column(Boolean, default=False)
    min_stock: Mapped[int] = mapped_column(Integer, default=0)
    target_stock: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    consumption_rate: Mapped[Optional[int]] = mapped_column(Integer, nullable=True, comment="Consumption rate in days")
    location_id: Mapped[Optional[int]] = mapped_column(ForeignKey("locations.id"), nullable=True)
    nfc_tag_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now)

    warehouse = relationship("Warehouse")
    location = relationship("Location")

    # Deleting a category cascades to its products (and through them to
    # stock_batches). InventoryAction rows retain their (now-orphaned)
    # category_id / product_id / stock_batch_id refs and are cleaned by the
    # endpoint via SET NULL updates so the audit trail is preserved.
    products = relationship(
        "Product",
        back_populates="category",
        cascade="all, delete-orphan",
        passive_deletes=False,
    )
