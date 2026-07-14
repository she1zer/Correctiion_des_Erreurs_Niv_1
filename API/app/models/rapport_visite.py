import json
from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.database import Base


class RapportVisite(Base):
    __tablename__ = "rapports_visite"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    numero_rapport: Mapped[str] = mapped_column(String(30), unique=True, index=True)
    date_visite: Mapped[datetime] = mapped_column(DateTime)
    client: Mapped[str] = mapped_column(String(200))
    correspondant_technique: Mapped[str] = mapped_column(String(200), default="")
    type_prestation: Mapped[str] = mapped_column(String(200), default="")
    type_batiment: Mapped[str] = mapped_column(String(200), default="")
    note_nb: Mapped[str] = mapped_column(Text, default="")
    nom_intervenant: Mapped[str] = mapped_column(String(200), default="")
    lignes_json: Mapped[str] = mapped_column(Text, default="[]")
    photos_json: Mapped[str] = mapped_column(Text, default="[]")
    created_by_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"), nullable=True
    )
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime, default=datetime.utcnow, onupdate=datetime.utcnow
    )

    def get_lignes(self) -> list[dict]:
        try:
            return json.loads(self.lignes_json or "[]")
        except json.JSONDecodeError:
            return []

    def set_lignes(self, lignes: list[dict]) -> None:
        self.lignes_json = json.dumps(lignes, ensure_ascii=False)

    def get_photos(self) -> list[dict]:
        try:
            return json.loads(self.photos_json or "[]")
        except json.JSONDecodeError:
            return []

    def set_photos(self, photos: list[dict]) -> None:
        self.photos_json = json.dumps(photos, ensure_ascii=False)
