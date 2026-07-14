from datetime import date, datetime

from sqlalchemy import Date, DateTime, Enum, ForeignKey, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.enums import RolePrise, StatutAction


class ActionPrise(Base):
    """Enregistrement quand un technicien prend une action en début de journée."""

    __tablename__ = "actions_prises"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    technicien_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    affaire_action_id: Mapped[int | None] = mapped_column(
        ForeignKey("affaire_actions.id", ondelete="CASCADE"), nullable=True
    )
    action_interne_id: Mapped[int | None] = mapped_column(
        ForeignKey("actions_internes.id", ondelete="CASCADE"), nullable=True
    )
    role_prise: Mapped[RolePrise] = mapped_column(
        Enum(RolePrise, native_enum=False, length=20)
    )
    date_prise: Mapped[date] = mapped_column(Date, default=date.today)
    date_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    date_fin: Mapped[date | None] = mapped_column(Date, nullable=True)
    statut: Mapped[StatutAction] = mapped_column(
        Enum(StatutAction, native_enum=False, length=20),
        default=StatutAction.non_entame,
    )
    commentaire: Mapped[str | None] = mapped_column(Text, nullable=True)
    support_travail: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    technicien = relationship("User", back_populates="prises")
    affaire_action = relationship("AffaireAction", back_populates="prises")
    action_interne = relationship("ActionInterne", back_populates="prises")
