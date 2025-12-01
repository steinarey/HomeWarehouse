from datetime import datetime, timedelta
from sqlalchemy import String, DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base
import secrets

def generate_invite_code():
    return secrets.token_urlsafe(8)

class Invite(Base):
    __tablename__ = "invites"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    code: Mapped[str] = mapped_column(String, unique=True, index=True, default=generate_invite_code)
    warehouse_id: Mapped[int] = mapped_column(ForeignKey("warehouses.id"), nullable=False)
    role: Mapped[str] = mapped_column(String, default="user") # admin, user, viewer
    created_by_user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    expires_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.utcnow() + timedelta(days=7))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    
    warehouse = relationship("Warehouse", back_populates="invites")
    created_by = relationship("User")
