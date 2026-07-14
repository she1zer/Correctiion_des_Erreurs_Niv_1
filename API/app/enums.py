import enum


class UserRole(str, enum.Enum):
    admin = "admin"
    technicien = "technicien"
    client = "client"


class StatutAffaire(str, enum.Enum):
    non_entame = "non_entame"
    en_cours = "en_cours"
    termine = "termine"
    bloque = "bloque"
    annule = "annule"


class StatutAction(str, enum.Enum):
    non_entame = "non_entame"
    en_cours = "en_cours"
    termine = "termine"
    annule = "annule"
    bloque = "bloque"


class Priorite(str, enum.Enum):
    haute = "haute"
    moyenne = "moyenne"
    basse = "basse"


class RolePrise(str, enum.Enum):
    responsable = "responsable"
    support = "support"


# Étapes standard de la fiche d'affaire ISITEK
ETAPES_AFFAIRE_STANDARD = [
    ("Etape 1: Expression du besoin - vous", ["observations"]),
    ("Etape 2: Visiter le site - Isitek", ["debut", "fin", "observations"]),
    ("Etape 3: offre commercial (devis) - Isitek", ["ref", "observations"]),
    ("Etape 4: Reception de la commande - vous", ["ref", "observations"]),
    ("Etape 5: Avance (accompte) - vous", ["observations"]),
    ("Etape 6: preparation de la commande - Isitek", ["debut", "fin", "observations"]),
    ("Etape 7: Livraison de la commande - Isitek", ["debut", "fin", "observations"]),
    ("Etape 8: Facturation - Isitek", ["ref", "observations"]),
    ("Etape 9: Reglement - vous", ["ref", "observations"]),
    ("Etape 10: Affaire termine - Isitek", ["observations"]),
    ("Etape 11: SAV - garantie - Isitek", ["debut", "fin", "observations"]),
    ("Etape 12: Retour satisfaction - client", ["observations"]),
]


STATUT_AFFAIRE_LABELS = {
    "non_entame": "Non entamé",
    "en_cours": "En cours",
    "termine": "Terminé",
    "bloque": "Bloqué",
    "annule": "Annulé",
}

STATUT_ACTION_LABELS = {
    "non_entame": "Non entamé",
    "en_cours": "En cours",
    "termine": "Terminé",
    "annule": "Annulé",
    "bloque": "Bloqué",
}

PRIORITE_LABELS = {
    "haute": "Haute",
    "moyenne": "Moyenne",
    "basse": "Basse",
}
