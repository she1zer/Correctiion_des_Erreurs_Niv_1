from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Date, DateTime, ForeignKey, Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class FichePointTraitement(Base):
    __tablename__ = "fiches_point_traitement"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    semaine: Mapped[int | None] = mapped_column(Integer, nullable=True)
    date_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    date_fin: Mapped[date | None] = mapped_column(Date, nullable=True)
    responsable: Mapped[str] = mapped_column(String(200), default="")
    signature_base64: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_by_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    lignes = relationship(
        "LignePointTraitement",
        back_populates="fiche",
        cascade="all, delete-orphan",
        order_by="LignePointTraitement.numero",
    )


class LignePointTraitement(Base):
    __tablename__ = "lignes_point_traitement"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    fiche_id: Mapped[int] = mapped_column(
        ForeignKey("fiches_point_traitement.id", ondelete="CASCADE"), index=True
    )
    numero: Mapped[int] = mapped_column(Integer)
    date_demande: Mapped[date | None] = mapped_column(Date, nullable=True)
    client: Mapped[str | None] = mapped_column(String(200), nullable=True)
    ref_demande: Mapped[str | None] = mapped_column(String(100), nullable=True)
    resume_demande: Mapped[str | None] = mapped_column(Text, nullable=True)
    ref_devis: Mapped[str | None] = mapped_column(String(100), nullable=True)
    montant_ht: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    statut: Mapped[str | None] = mapped_column(String(100), nullable=True)

    fiche = relationship("FichePointTraitement", back_populates="lignes")
