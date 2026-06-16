import secrets
from datetime import datetime, timedelta
from typing import Optional

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.core.time import utc_now
from app.db.base import Base


def generate_invite_code():
    return secrets.token_urlsafe(8)


def _default_expiry() -> datetime:
    return utc_now() + timedelta(days=7)


class Invite(Base):
    __tablename__ = "invites"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    code: Mapped[str] = mapped_column(
        String, unique=True, index=True, default=generate_invite_code
    )
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    role: Mapped[str] = mapped_column(String, default="user")  # admin, user, viewer
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, default=_default_expiry)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utc_now)

    # New in D1: bound usage. NULL = unlimited (until expiry). Counter tracks
    # successful redemptions. `revoked` is the admin off-switch.
    max_uses: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    uses: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    revoked: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    warehouse = relationship("Warehouse", back_populates="invites")
    created_by = relationship("User")
