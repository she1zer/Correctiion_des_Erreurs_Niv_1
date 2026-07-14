from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.enums import UserRole
from app.models.user import User
from app.schemas.user import LoginRequest, Token, UserCreate, UserResponse
from app.security import (
    authenticate_user,
    create_access_token,
    get_current_user,
    get_user_by_email,
    hash_password,
)
from app.services.authorized_phone_service import is_employee_phone_authorized

router = APIRouter(prefix="/api/auth", tags=["Authentification"])


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
def register(data: UserCreate, db: Session = Depends(get_db)):
    if get_user_by_email(db, data.email):
        raise HTTPException(status_code=400, detail="Cet email est déjà utilisé")
    if data.role == UserRole.admin:
        raise HTTPException(status_code=403, detail="La création de compte admin n'est pas autorisée")
    if data.role not in (UserRole.client, UserRole.technicien):
        raise HTTPException(status_code=400, detail="Rôle invalide")
    if data.role == UserRole.technicien:
        if not data.telephone or not data.telephone.strip():
            raise HTTPException(
                status_code=400,
                detail="Le numéro de téléphone est obligatoire pour les employés",
            )
        if not is_employee_phone_authorized(db, data.telephone):
            raise HTTPException(
                status_code=403,
                detail=(
                    "Ce numéro de téléphone n'est pas autorisé. "
                    "Demandez à l'administrateur ISITEK d'enregistrer votre numéro."
                ),
            )
    user = User(
        email=data.email,
        hashed_password=hash_password(data.password),
        nom=data.nom,
        prenom=data.prenom,
        telephone=data.telephone,
        poste=data.poste,
        latitude=data.latitude,
        longitude=data.longitude,
        role=data.role,
        can_create_affaire=False,
        can_create_devis=False if data.role == UserRole.technicien else True,
        can_create_rapport=False,
        can_manage_actions_internes=False,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.post("/login", response_model=Token)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = authenticate_user(db, data.email, data.password)
    if not user:
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    token = create_access_token(
        {"sub": user.email},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )
    return Token(access_token=token, user=user)


@router.post("/token", response_model=Token)
def login_form(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    user = authenticate_user(db, form.username, form.password)
    if not user:
        raise HTTPException(status_code=401, detail="Email ou mot de passe incorrect")
    token = create_access_token(
        {"sub": user.email},
        expires_delta=timedelta(minutes=settings.access_token_expire_minutes),
    )
    return Token(access_token=token, user=user)


@router.get("/me", response_model=UserResponse)
def me(current_user: User = Depends(get_current_user)):
    return current_user
