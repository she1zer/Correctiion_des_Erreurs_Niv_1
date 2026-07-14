from datetime import datetime

from pydantic import BaseModel, Field


class ProduitLigne(BaseModel):
    reference: str = ""
    designation: str = ""
    quantite: float = 0
    prix_unitaire_ht: float = 0
    remise_pourcentage: float = 0
    unite: str = "U"


class DevisRenderRequest(BaseModel):
    """Payload pour génération Excel/PDF proforma (modèle az.jpeg)."""

    numero_devis: str | None = None
    date_emission: str | None = None
    date_devis: datetime | None = None
    affaire_suivie_par: str = "Amadou OUATTARA"
    ref_demande: str | None = None
    contact: str | None = None
    client_nom: str = ""
    client_numero_cc: str | None = None
    client_da: str | None = None
    telephone: str | None = None
    objet_demande: str = ""
    validite_offre: str = "1 mois"
    delai_livraison: str = "1 semaine"
    moyen_reglement: str = "Chèque/Virement"
    libelle_cheque: str = "ISITEK"
    remise_exceptionnelle_active: bool = True
    remise_exceptionnelle_pct: float = 10
    condition_reglement: str = "habituelles"
    acompte_pourcentage: int = 40
    lignes: list[ProduitLigne] = Field(default_factory=list)


class DevisCreate(BaseModel):
    numero_devis: str | None = None
    contact: str | None = None
    client_nom: str = ""
    client_numero_cc: str | None = None
    client_da: str | None = None
    affaire_suivie_par: str | None = "Amadou OUATTARA"
    ref_demande: str | None = None
    telephone: str | None = None
    objet_demande: str | None = None
    remise_exceptionnelle_active: bool = True
    remise_exceptionnelle_pct: float = 10
    acompte_pourcentage: int = 40
    validite_offre: str = "1 Mois"
    delai_livraison: str = "Disponible"
    moyen_reglement: str = "Chèque/ virement"
    libelle_cheque: str = "ISITEK"
    condition_reglement: str = "habituelles"
    lignes: list[ProduitLigne] = Field(default_factory=list)
    email_message_id: str | None = None
    email_subject: str | None = None
    email_from: str | None = None
    demande_id: int | None = None


class DevisUpdate(BaseModel):
    contact: str | None = None
    client_nom: str | None = None
    client_numero_cc: str | None = None
    client_da: str | None = None
    affaire_suivie_par: str | None = None
    ref_demande: str | None = None
    telephone: str | None = None
    objet_demande: str | None = None
    remise_exceptionnelle_active: bool | None = None
    remise_exceptionnelle_pct: float | None = None
    acompte_pourcentage: int | None = None
    validite_offre: str | None = None
    delai_livraison: str | None = None
    moyen_reglement: str | None = None
    libelle_cheque: str | None = None
    condition_reglement: str | None = None
    lignes: list[ProduitLigne] | None = None
    demande_id: int | None = None


class DevisShareCreate(BaseModel):
    user_id: int
    can_edit: bool = True


class DevisShareResponse(BaseModel):
    id: int
    devis_id: int
    shared_with_id: int
    shared_with_name: str
    shared_with_email: str
    can_edit: bool
    created_at: datetime

    class Config:
        from_attributes = True


class DevisResponse(BaseModel):
    id: int
    numero_devis: str
    date_devis: datetime
    contact: str | None
    client_nom: str
    client_numero_cc: str | None
    client_da: str | None
    affaire_suivie_par: str | None = None
    ref_demande: str | None = None
    telephone: str | None = None
    objet_demande: str | None = None
    remise_exceptionnelle_active: bool = True
    remise_exceptionnelle_pct: float = 10
    acompte_pourcentage: int
    validite_offre: str
    delai_livraison: str
    moyen_reglement: str
    libelle_cheque: str
    condition_reglement: str = "habituelles"
    lignes: list[ProduitLigne]
    total_ht_brut: int
    total_remise: int
    total_ht_net: int
    email_message_id: str | None
    email_subject: str | None
    email_from: str | None
    demande_id: int | None
    affaire_id: int | None = None
    created_by_id: int | None = None
    created_by_name: str | None = None
    is_owner: bool = False
    is_shared: bool = False
    can_edit: bool = True
    created_at: datetime

    class Config:
        from_attributes = True


class CreateAffaireFromDevisRequest(BaseModel):
    numero_affaire: str | None = None
    domaine: str = "FOURNITURE"
    type_affaire: str = "FOURNITURE"
    creer_etapes_standard: bool = True


class EmailSummary(BaseModel):
    message_id: str
    subject: str
    from_address: str
    from_name: str | None = None
    date: str
    preview: str
    references: list[str] = Field(default_factory=list)


class EmailAnalyzeRequest(BaseModel):
    message_id: str | None = None
    raw_text: str | None = None
    subject: str | None = None
    from_address: str | None = None


class EmailAnalyzeResponse(BaseModel):
    references: list[str]
    client_nom: str | None = None
    contact: str | None = None
    client_da: str | None = None
    suggested_designations: dict[str, str] = Field(default_factory=dict)


class ProductSearchResult(BaseModel):
    title: str
    url: str
    snippet: str
    source: str = "web"
    price: float | None = None
    price_label: str = ""
    merchant: str = ""
    image_url: str = ""


class ProductSearchResponse(BaseModel):
    reference: str
    results: list[ProductSearchResult]
    search_url: str
    shopping_url: str = ""
    suggested_designation: str = ""
