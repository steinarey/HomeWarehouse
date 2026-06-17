from datetime import datetime
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Index, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.time import utc_now
from app.db.base import Base


class WarehouseConnector(Base):
    """Per-warehouse external integration (Microsoft To Do, future: others).

    Tokens are stored as Fernet-encrypted strings; the model only ever holds
    the ciphertext. Use `app.integrations.microsoft_todo.tokens` to
    encrypt/decrypt + refresh.
    """

    __tablename__ = "warehouse_connectors"
    __table_args__ = (
        UniqueConstraint("warehouse_id", "kind", name="uq_warehouse_connector_kind"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    kind: Mapped[str] = mapped_column(String, nullable=False)
    status: Mapped[str] = mapped_column(String, default="disconnected", nullable=False)

    # Microsoft account identity (subject claim + UPN/email for display).
    ms_user_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    ms_user_email: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    access_token_enc: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    refresh_token_enc: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    access_token_expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)

    selected_list_id: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    selected_list_name: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    last_synced_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    last_error: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now, onupdate=utc_now)

    warehouse = relationship("Warehouse")
