from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.database import Base, SessionLocal, engine
from app.enums import UserRole
from app.models.authorized_phone import AuthorizedEmployeePhone
from app.models import Banque, User
from app.routers import (
    actions_internes,
    affaires,
    auth,
    authorized_phones,
    rapport_visite,
    rapports,
    search,
    technicien,
    users,
    demandes,
    messages,
    point_traitement,
    devis,
    staff_messages,
    ai,
    caisse,
    feedback,
    astuces,
    hub,
)
from app.security import hash_password


def seed_initial_data():
    db = SessionLocal()
    try:
        if not db.query(Banque).first():
            for nom in ["BICICI", "SGBCI", "BOA", "Ecobank", "NSIA Banque"]:
                db.add(Banque(nom=nom))
            db.commit()

        if not db.query(User).filter(User.email == "admin@isitek.ci").first():
            admin = User(
                email="admin@isitek.ci",
                hashed_password=hash_password("admin123"),
                nom="ADMIN",
                prenom="ISITEK",
                telephone="+22500000000",
                poste="Administrateur",
                role=UserRole.admin,
                can_create_affaire=True,
                can_create_devis=True,
                can_create_rapport=True,
                can_manage_actions_internes=True,
            )
            db.add(admin)
            db.commit()
            if not db.query(AuthorizedEmployeePhone).first():
                db.add(
                    AuthorizedEmployeePhone(
                        telephone=admin.telephone or "+22500000000",
                        label="Admin ISITEK",
                    )
                )
                db.commit()
    finally:
        db.close()


def run_migrations():
    db = SessionLocal()
    try:
        from sqlalchemy import text
        # Check and add columns to demandes
        cols_demandes = db.execute(text("SHOW COLUMNS FROM demandes")).fetchall()
        col_names_demandes = [c[0] for c in cols_demandes]
        demande_migrations = {
            "photos": "TEXT NULL",
            "accompte_pourcentage": "INT NULL",
            "garantie_mois": "INT NULL",
            "garantie_debut": "DATE NULL",
            "garantie_fin": "DATE NULL",
            "etapes_sautees": "VARCHAR(200) NULL",
            "etapes_custom": "TEXT NULL",
        }
        for col, col_type in demande_migrations.items():
            if col not in col_names_demandes:
                db.execute(text(f"ALTER TABLE demandes ADD COLUMN {col} {col_type}"))
                db.commit()
                col_names_demandes.append(col)

        # Check and add columns to affaires
        cols_affaires = db.execute(text("SHOW COLUMNS FROM affaires")).fetchall()
        col_names_affaires = [c[0] for c in cols_affaires]
        if "demande_id" not in col_names_affaires:
            db.execute(text("ALTER TABLE affaires ADD COLUMN demande_id INT NULL"))
            try:
                db.execute(text("ALTER TABLE affaires ADD CONSTRAINT fk_affaires_demande FOREIGN KEY (demande_id) REFERENCES demandes(id) ON DELETE SET NULL"))
            except Exception:
                pass
            db.commit()
        if "satisfaction_etoiles" not in col_names_affaires:
            db.execute(text("ALTER TABLE affaires ADD COLUMN satisfaction_etoiles INT NULL"))
            db.commit()
        if "satisfaction_commentaire" not in col_names_affaires:
            db.execute(text("ALTER TABLE affaires ADD COLUMN satisfaction_commentaire TEXT NULL"))
            db.commit()

        # Check and add columns to affaire_actions
        cols_actions = db.execute(text("SHOW COLUMNS FROM affaire_actions")).fetchall()
        col_names_actions = [c[0] for c in cols_actions]
        if "est_saute" not in col_names_actions:
            db.execute(text("ALTER TABLE affaire_actions ADD COLUMN est_saute TINYINT(1) NOT NULL DEFAULT 0"))
            db.commit()
        if "pourcentage_acompte" not in col_names_actions:
            db.execute(text("ALTER TABLE affaire_actions ADD COLUMN pourcentage_acompte INT NULL"))
            db.commit()
        if "garantie_mois" not in col_names_actions:
            db.execute(text("ALTER TABLE affaire_actions ADD COLUMN garantie_mois INT NULL"))
            db.commit()

        # Permissions utilisateurs
        cols_users = db.execute(text("SHOW COLUMNS FROM users")).fetchall()
        col_names_users = [c[0] for c in cols_users]
        user_perm = {
            "can_create_affaire": "TINYINT(1) NOT NULL DEFAULT 0",
            "can_create_devis": "TINYINT(1) NOT NULL DEFAULT 0",
            "can_create_rapport": "TINYINT(1) NOT NULL DEFAULT 0",
            "can_manage_actions_internes": "TINYINT(1) NOT NULL DEFAULT 0",
            "can_access_caisse": "TINYINT(1) NOT NULL DEFAULT 0",
            "can_caisse_controle": "TINYINT(1) NOT NULL DEFAULT 0",
            "can_caisse_livre": "TINYINT(1) NOT NULL DEFAULT 0",
        }
        for col, col_type in user_perm.items():
            if col not in col_names_users:
                db.execute(text(f"ALTER TABLE users ADD COLUMN {col} {col_type}"))
                db.commit()

        # Fiches contrôle caisse — pages 2 sections
        try:
            cols_fc = db.execute(text("SHOW COLUMNS FROM fiches_controle_caisse")).fetchall()
            col_names_fc = [c[0] for c in cols_fc]
            fc_migrations = {
                "page_id": "INT NULL",
                "slot": "INT NOT NULL DEFAULT 1",
                "sections_par_page": "INT NOT NULL DEFAULT 2",
            }
            for col, col_type in fc_migrations.items():
                if col not in col_names_fc:
                    db.execute(text(f"ALTER TABLE fiches_controle_caisse ADD COLUMN {col} {col_type}"))
                    db.commit()
        except Exception:
            pass

        # Lien devis ↔ affaire
        if col_names_affaires and "devis_proforma_id" not in col_names_affaires:
            db.execute(text("ALTER TABLE affaires ADD COLUMN devis_proforma_id INT NULL"))
            db.commit()
        try:
            cols_devis = db.execute(text("SHOW COLUMNS FROM devis_proformas")).fetchall()
            col_names_devis = [c[0] for c in cols_devis]
            devis_migrations = {
                "affaire_id": "INT NULL",
                "affaire_suivie_par": "VARCHAR(120) NULL",
                "ref_demande": "VARCHAR(120) NULL",
                "telephone": "VARCHAR(50) NULL",
                "objet_demande": "VARCHAR(500) NULL",
                "remise_exceptionnelle_active": "TINYINT(1) NOT NULL DEFAULT 1",
                "remise_exceptionnelle_pct": "FLOAT NOT NULL DEFAULT 10",
                "condition_reglement": "VARCHAR(30) NOT NULL DEFAULT 'habituelles'",
            }
            for col, col_type in devis_migrations.items():
                if col not in col_names_devis:
                    db.execute(text(f"ALTER TABLE devis_proformas ADD COLUMN {col} {col_type}"))
                    db.commit()
        except Exception:
            pass

        # Check and add columns to users
        cols_users = db.execute(text("SHOW COLUMNS FROM users")).fetchall()
        col_names_users = [c[0] for c in cols_users]
        user_migrations = {
            "poste": "VARCHAR(100) NULL",
            "latitude": "DOUBLE NULL",
            "longitude": "DOUBLE NULL",
        }
        for col, col_type in user_migrations.items():
            if col not in col_names_users:
                db.execute(text(f"ALTER TABLE users ADD COLUMN {col} {col_type}"))
                db.commit()

        # Check and add lat/lng to demandes
        if col_names_demandes:
            demande_geo = {
                "latitude": "DOUBLE NULL",
                "longitude": "DOUBLE NULL",
            }
            for col, col_type in demande_geo.items():
                if col not in col_names_demandes:
                    db.execute(text(f"ALTER TABLE demandes ADD COLUMN {col} {col_type}"))
                    db.commit()
    except Exception as e:
        print(f"Migration error (ignoring): {e}")
    finally:
        db.close()


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    run_migrations()
    seed_initial_data()
    yield


app = FastAPI(
    title="ISITEK Connect API",
    description="API de gestion des affaires, actions internes et plans d'action ISITEK SARL",
    version="1.0.0",
    lifespan=lifespan,
)

import os
from fastapi.staticfiles import StaticFiles

# Create uploads folder if not exists
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(authorized_phones.router)
app.include_router(search.router)
app.include_router(affaires.router)
app.include_router(actions_internes.router)
app.include_router(technicien.router)
app.include_router(rapport_visite.router)
app.include_router(rapports.router)
app.include_router(demandes.router)
app.include_router(messages.router)
app.include_router(point_traitement.router)
app.include_router(devis.router)
app.include_router(staff_messages.router)
app.include_router(ai.router)
app.include_router(caisse.router)
app.include_router(feedback.router)
app.include_router(astuces.router)
app.include_router(hub.router)


@app.get("/bugs", include_in_schema=False)
def bugs_page_redirect():
    """Redirection vers la page web des signalements."""
    from fastapi.responses import RedirectResponse
    return RedirectResponse(url="/api/feedback/web/bugs")


@app.get("/")
def root():
    return {
        "message": "ISITEK Connect API",
        "docs": "/docs",
        "bugs_web": "/bugs",
        "version": "1.0.0",
    }


@app.get("/health")
def health():
    return {"status": "ok"}
