from datetime import datetime, date
from sqlalchemy import Float, ForeignKey, Integer, String, Text, DateTime, Date
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.database import Base

class Demande(Base):
    __tablename__ = "demandes"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    client_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"))
    domaine: Mapped[str] = mapped_column(String(200))
    type_prestation: Mapped[str] = mapped_column(String(100))
    description: Mapped[str] = mapped_column(Text)
    adresse: Mapped[str] = mapped_column(String(500))
    statut: Mapped[str] = mapped_column(String(50), default="recue")
    devis_montant: Mapped[int | None] = mapped_column(Integer, nullable=True)
    rating: Mapped[int | None] = mapped_column(Integer, nullable=True)
    avis: Mapped[str | None] = mapped_column(Text, nullable=True)
    photos: Mapped[str | None] = mapped_column(Text, nullable=True)
    accompte_pourcentage: Mapped[int | None] = mapped_column(Integer, nullable=True)
    garantie_mois: Mapped[int | None] = mapped_column(Integer, nullable=True)
    garantie_debut: Mapped[date | None] = mapped_column(Date, nullable=True)
    garantie_fin: Mapped[date | None] = mapped_column(Date, nullable=True)
    etapes_sautees: Mapped[str | None] = mapped_column(String(200), nullable=True)
    etapes_custom: Mapped[str | None] = mapped_column(Text, nullable=True)
    latitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    longitude: Mapped[float | None] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    client = relationship("User", foreign_keys=[client_id])
