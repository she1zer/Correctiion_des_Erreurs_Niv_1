from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, Float, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.enums import UserRole


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    hashed_password: Mapped[str] = mapped_column(String(255))
    nom: Mapped[str] = mapped_column(String(100))
    prenom: Mapped[str] = mapped_column(String(100))
    telephone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    poste: Mapped[str | None] = mapped_column(String(100), nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, native_enum=False, length=20), default=UserRole.client
    )
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    can_create_affaire: Mapped[bool] = mapped_column(Boolean, default=False)
    can_create_devis: Mapped[bool] = mapped_column(Boolean, default=False)
    can_create_rapport: Mapped[bool] = mapped_column(Boolean, default=False)
    can_manage_actions_internes: Mapped[bool] = mapped_column(Boolean, default=False)
    can_access_caisse: Mapped[bool] = mapped_column(Boolean, default=False)
    can_caisse_controle: Mapped[bool] = mapped_column(Boolean, default=False)
    can_caisse_livre: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    actions_affaire_responsable = relationship(
        "AffaireAction", back_populates="responsable", foreign_keys="AffaireAction.responsable_id"
    )
    actions_affaire_support = relationship(
        "AffaireAction", back_populates="support", foreign_keys="AffaireAction.support_id"
    )
    actions_internes_responsable = relationship(
        "ActionInterne", back_populates="responsable", foreign_keys="ActionInterne.responsable_id"
    )
    actions_internes_support = relationship(
        "ActionInterne", back_populates="support", foreign_keys="ActionInterne.support_id"
    )
    prises = relationship("ActionPrise", back_populates="technicien")
