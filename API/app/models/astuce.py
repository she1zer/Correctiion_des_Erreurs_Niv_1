from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class Astuce(Base):
    """Conseils / astuces ISITEK gérés par l'administrateur."""

    __tablename__ = "astuces"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    emoji: Mapped[str] = mapped_column(String(16), default="💡")
    title: Mapped[str] = mapped_column(String(200))
    summary: Mapped[str] = mapped_column(String(500))
    detail: Mapped[str] = mapped_column(Text)
    category: Mapped[str] = mapped_column(String(80), index=True)
    icon_name: Mapped[str] = mapped_column(String(80), default="lightbulb_rounded")
    gradient_start: Mapped[str] = mapped_column(String(10), default="#FFD54F")
    gradient_end: Mapped[str] = mapped_column(String(10), default="#F9A825")
    accent_color: Mapped[str] = mapped_column(String(10), default="#F57F17")
    ordre: Mapped[int] = mapped_column(Integer, default=0, index=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )
