from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Banque(Base):
    __tablename__ = "banques"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    nom: Mapped[str] = mapped_column(String(100), unique=True)

    actions = relationship("AffaireAction", back_populates="banque")
