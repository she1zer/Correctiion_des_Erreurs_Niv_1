from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, String
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class AuthorizedEmployeePhone(Base):
    """Numéros autorisés pour l'inscription des employés."""

    __tablename__ = "authorized_employee_phones"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    telephone: Mapped[str] = mapped_column(String(30), index=True)
    label: Mapped[str | None] = mapped_column(String(120), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    created_by_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
