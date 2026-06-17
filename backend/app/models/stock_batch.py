from datetime import datetime, date
from typing import Optional
from sqlalchemy import Integer, ForeignKey, DateTime, Date
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.time import utc_now
from app.db.base import Base

class StockBatch(Base):
    __tablename__ = "stock_batches"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    product_id: Mapped[int] = mapped_column(ForeignKey("products.id"), nullable=False)
    location_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("locations.id", ondelete="SET NULL"),
        nullable=True,
    )
    quantity: Mapped[int] = mapped_column(Integer, default=0) # non-negative check to be enforced in logic/DB constraint
    expiry_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now)

    product = relationship("Product", back_populates="stock_batches")
    location = relationship("Location")
    warehouse = relationship("Warehouse")
