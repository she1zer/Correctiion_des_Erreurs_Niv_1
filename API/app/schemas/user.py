from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.enums import UserRole


class UserBase(BaseModel):
    email: EmailStr
    nom: str
    prenom: str
    telephone: str | None = None
    poste: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    role: UserRole = UserRole.client


class UserCreate(UserBase):
    password: str = Field(min_length=6)


class UserUpdate(BaseModel):
    nom: str | None = None
    prenom: str | None = None
    telephone: str | None = None
    poste: str | None = None
    latitude: float | None = None
    longitude: float | None = None
    role: UserRole | None = None
    is_active: bool | None = None
    password: str | None = Field(default=None, min_length=6)
    can_create_affaire: bool | None = None
    can_create_devis: bool | None = None
    can_create_rapport: bool | None = None
    can_manage_actions_internes: bool | None = None
    can_access_caisse: bool | None = None
    can_caisse_controle: bool | None = None
    can_caisse_livre: bool | None = None


class UserPermissions(BaseModel):
    can_create_affaire: bool = False
    can_create_devis: bool = False
    can_create_rapport: bool = False
    can_manage_actions_internes: bool = False
    can_access_caisse: bool = False
    can_caisse_controle: bool = False
    can_caisse_livre: bool = False


class UserResponse(UserBase):
    id: int
    is_active: bool
    can_create_affaire: bool = False
    can_create_devis: bool = False
    can_create_rapport: bool = False
    can_manage_actions_internes: bool = False
    can_access_caisse: bool = False
    can_caisse_controle: bool = False
    can_caisse_livre: bool = False
    created_at: datetime

    class Config:
        from_attributes = True


class UserBrief(BaseModel):
    id: int
    nom: str
    prenom: str
    email: str
    poste: str | None = None
    role: UserRole

    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse


class LoginRequest(BaseModel):
    email: EmailStr
    password: str
