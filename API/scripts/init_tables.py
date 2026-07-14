"""Crée les tables et les données initiales dans la base isitek (XAMPP)."""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.database import Base, SessionLocal, engine
from app.enums import UserRole
from app.main import seed_initial_data
from app.models import Banque, User


def main():
    print("Connexion à la base isitek...")
    Base.metadata.create_all(bind=engine)
    seed_initial_data()

    db = SessionLocal()
    try:
        users = db.query(User).count()
        banques = db.query(Banque).count()
        tables = list(Base.metadata.tables.keys())
    finally:
        db.close()

    print("OK — Tables créées :", ", ".join(tables))
    print(f"     Utilisateurs : {users}  |  Banques : {banques}")
    print("     Admin : admin@isitek.ci / admin123")


if __name__ == "__main__":
    main()
