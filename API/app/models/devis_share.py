from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class DevisShare(Base):
    __tablename__ = "devis_shares"
    __table_args__ = (UniqueConstraint("devis_id", "shared_with_id", name="uq_devis_share"),)

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    devis_id: Mapped[int] = mapped_column(ForeignKey("devis_proformas.id", ondelete="CASCADE"), index=True)
    shared_by_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    shared_with_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    can_edit: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
