from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    JSON,
    Boolean,
    Date,
    DateTime,
    Enum,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base
from app.enums import StatutAction, StatutAffaire


class Affaire(Base):
    __tablename__ = "affaires"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    numero_affaire: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    responsable_nom: Mapped[str] = mapped_column(String(100))
    responsable_prenom: Mapped[str] = mapped_column(String(100))
    responsable_role: Mapped[str] = mapped_column(String(100))
    date_ouverture: Mapped[date] = mapped_column(Date)
    client_nom: Mapped[str] = mapped_column(String(200))
    numero_commande: Mapped[str | None] = mapped_column(String(100), nullable=True)
    libelle_affaire: Mapped[str] = mapped_column(String(500))
    domaine: Mapped[str] = mapped_column(String(200))
    type_affaire: Mapped[str | None] = mapped_column(String(100), nullable=True)
    montant_affaire: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    date_livraison_bc: Mapped[date | None] = mapped_column(Date, nullable=True)
    correspondant_nom: Mapped[str | None] = mapped_column(String(200), nullable=True)
    correspondant_telephone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    correspondant_email: Mapped[str | None] = mapped_column(String(255), nullable=True)
    statut: Mapped[StatutAffaire] = mapped_column(
        Enum(StatutAffaire, native_enum=False, length=20),
        default=StatutAffaire.non_entame,
    )
    demande_id: Mapped[int | None] = mapped_column(ForeignKey("demandes.id", ondelete="SET NULL"), nullable=True)
    devis_proforma_id: Mapped[int | None] = mapped_column(ForeignKey("devis_proformas.id", ondelete="SET NULL"), nullable=True)
    satisfaction_etoiles: Mapped[int | None] = mapped_column(Integer, nullable=True)
    satisfaction_commentaire: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    actions = relationship(
        "AffaireAction",
        back_populates="affaire",
        cascade="all, delete-orphan",
        order_by="AffaireAction.ordre",
    )


class AffaireAction(Base):
    __tablename__ = "affaire_actions"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    affaire_id: Mapped[int] = mapped_column(ForeignKey("affaires.id", ondelete="CASCADE"))
    libelle: Mapped[str] = mapped_column(String(200))
    ordre: Mapped[int] = mapped_column(Integer, default=0)
    champs_actifs: Mapped[list | None] = mapped_column(JSON, nullable=True)

    responsable_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    support_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )

    date_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    date_fin: Mapped[date | None] = mapped_column(Date, nullable=True)
    date_action: Mapped[date | None] = mapped_column(Date, nullable=True)
    ref: Mapped[str | None] = mapped_column(String(200), nullable=True)
    agence: Mapped[str | None] = mapped_column(String(200), nullable=True)
    mode: Mapped[str | None] = mapped_column(String(100), nullable=True)
    fournisseur: Mapped[str | None] = mapped_column(String(200), nullable=True)
    observations: Mapped[str | None] = mapped_column(Text, nullable=True)
    banque_id: Mapped[int | None] = mapped_column(
        ForeignKey("banques.id", ondelete="SET NULL"), nullable=True
    )

    statut: Mapped[StatutAction] = mapped_column(
        Enum(StatutAction, native_enum=False, length=20),
        default=StatutAction.non_entame,
    )
    commentaire: Mapped[str | None] = mapped_column(Text, nullable=True)
    termine: Mapped[bool] = mapped_column(Boolean, default=False)
    est_saute: Mapped[bool] = mapped_column(Boolean, default=False)
    pourcentage_acompte: Mapped[int | None] = mapped_column(Integer, nullable=True)
    garantie_mois: Mapped[int | None] = mapped_column(Integer, nullable=True)

    affaire = relationship("Affaire", back_populates="actions")
    responsable = relationship("User", foreign_keys=[responsable_id], back_populates="actions_affaire_responsable")
    support = relationship("User", foreign_keys=[support_id], back_populates="actions_affaire_support")
    banque = relationship("Banque", back_populates="actions")
    prises = relationship("ActionPrise", back_populates="affaire_action", cascade="all, delete-orphan")
