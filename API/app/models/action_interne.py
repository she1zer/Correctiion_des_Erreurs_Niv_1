from datetime import date, datetime

from sqlalchemy import Date, DateTime, Enum, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.enums import Priorite, StatutAction


class ActionInterne(Base):
    __tablename__ = "actions_internes"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    nom: Mapped[str] = mapped_column(String(300))
    responsable_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    support_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    date_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    date_fin: Mapped[date | None] = mapped_column(Date, nullable=True)
    statut: Mapped[StatutAction] = mapped_column(
        Enum(StatutAction, native_enum=False, length=20),
        default=StatutAction.non_entame,
    )
    priorite: Mapped[Priorite] = mapped_column(
        Enum(Priorite, native_enum=False, length=20), default=Priorite.moyenne
    )
    commentaire: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    responsable = relationship(
        "User", foreign_keys=[responsable_id], back_populates="actions_internes_responsable"
    )
    support = relationship(
        "User", foreign_keys=[support_id], back_populates="actions_internes_support"
    )
    prises = relationship(
        "ActionPrise", back_populates="action_interne", cascade="all, delete-orphan"
    )
