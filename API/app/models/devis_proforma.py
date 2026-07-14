import json
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, Text, Float
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class DevisProforma(Base):
    __tablename__ = "devis_proformas"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    numero_devis: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    date_devis: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    contact: Mapped[str | None] = mapped_column(String(100), nullable=True)
    client_nom: Mapped[str] = mapped_column(String(200), default="")
    client_numero_cc: Mapped[str | None] = mapped_column(String(50), nullable=True)
    client_da: Mapped[str | None] = mapped_column(String(50), nullable=True)
    acompte_pourcentage: Mapped[int] = mapped_column(Integer, default=40)
    validite_offre: Mapped[str] = mapped_column(String(50), default="1 Mois")
    delai_livraison: Mapped[str] = mapped_column(String(100), default="Disponible")
    moyen_reglement: Mapped[str] = mapped_column(String(100), default="Chèque/ virement")
    libelle_cheque: Mapped[str] = mapped_column(String(50), default="ISITEK")
    lignes_json: Mapped[str] = mapped_column(Text, default="[]")
    total_ht_brut: Mapped[int] = mapped_column(Integer, default=0)
    total_remise: Mapped[int] = mapped_column(Integer, default=0)
    total_ht_net: Mapped[int] = mapped_column(Integer, default=0)
    email_message_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    email_subject: Mapped[str | None] = mapped_column(String(500), nullable=True)
    email_from: Mapped[str | None] = mapped_column(String(255), nullable=True)
    created_by_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    demande_id: Mapped[int | None] = mapped_column(ForeignKey("demandes.id", ondelete="SET NULL"), nullable=True)
    affaire_id: Mapped[int | None] = mapped_column(ForeignKey("affaires.id", ondelete="SET NULL"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    affaire_suivie_par: Mapped[str | None] = mapped_column(String(120), nullable=True)
    ref_demande: Mapped[str | None] = mapped_column(String(120), nullable=True)
    telephone: Mapped[str | None] = mapped_column(String(50), nullable=True)
    objet_demande: Mapped[str | None] = mapped_column(String(500), nullable=True)
    remise_exceptionnelle_active: Mapped[bool] = mapped_column(Boolean, default=True)
    remise_exceptionnelle_pct: Mapped[float] = mapped_column(Float, default=10.0)
    condition_reglement: Mapped[str] = mapped_column(String(30), default="habituelles")

    def get_lignes(self) -> list[dict]:
        try:
            return json.loads(self.lignes_json or "[]")
        except json.JSONDecodeError:
            return []

    def set_lignes(self, lignes: list[dict]) -> None:
        self.lignes_json = json.dumps(lignes, ensure_ascii=False)
