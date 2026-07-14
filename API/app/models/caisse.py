from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class FicheControleCaisse(Base):
    __tablename__ = "fiches_controle_caisse"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    semaine: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    annee: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    date_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    date_fin: Mapped[date | None] = mapped_column(Date, nullable=True)
    solde_theorique: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    solde_reel: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    ecart_avt: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    observations: Mapped[str] = mapped_column(Text, default="")
    ecart_apt: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    sig_rep_operations: Mapped[str] = mapped_column(String(200), default="")
    sig_comptable: Mapped[str] = mapped_column(String(200), default="")
    sig_direction: Mapped[str] = mapped_column(String(200), default="")
    page_id: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    slot: Mapped[int] = mapped_column(Integer, default=1)
    sections_par_page: Mapped[int] = mapped_column(Integer, default=2)
    created_by_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )


class LivreCaisseHebdo(Base):
    __tablename__ = "livres_caisse_hebdo"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    annee: Mapped[int | None] = mapped_column(Integer, nullable=True, index=True)
    mois: Mapped[int | None] = mapped_column(Integer, nullable=True)
    semaine: Mapped[int | None] = mapped_column(Integer, nullable=True)
    periode_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    periode_fin: Mapped[date | None] = mapped_column(Date, nullable=True)
    montant_caisse_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    montant_caisse_valeur: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    date_signature: Mapped[date | None] = mapped_column(Date, nullable=True)
    signature_finale: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_by_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    lignes = relationship(
        "LigneLivreCaisse",
        back_populates="livre",
        cascade="all, delete-orphan",
        order_by="LigneLivreCaisse.numero",
    )


class LigneLivreCaisse(Base):
    __tablename__ = "lignes_livre_caisse"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    livre_id: Mapped[int] = mapped_column(
        ForeignKey("livres_caisse_hebdo.id", ondelete="CASCADE"), index=True
    )
    numero: Mapped[int] = mapped_column(Integer)
    date_operation: Mapped[date | None] = mapped_column(Date, nullable=True)
    numero_piece: Mapped[str | None] = mapped_column(String(80), nullable=True)
    nom_prenoms: Mapped[str | None] = mapped_column(String(200), nullable=True)
    detail_operation: Mapped[str | None] = mapped_column(Text, nullable=True)
    entree: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    sortie: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    solde: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True, index=True)
    signature_beneficiaire: Mapped[str | None] = mapped_column(String(200), nullable=True)

    livre = relationship("LivreCaisseHebdo", back_populates="lignes")
