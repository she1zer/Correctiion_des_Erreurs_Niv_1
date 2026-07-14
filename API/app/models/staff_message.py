from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class StaffMessage(Base):
    """Messagerie interne technicien ↔ administrateur."""

    __tablename__ = "staff_messages"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    technicien_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    sender_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    sender_role: Mapped[str] = mapped_column(String(20))  # technicien | admin
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    technicien = relationship("User", foreign_keys=[technicien_id])
    sender = relationship("User", foreign_keys=[sender_id])
