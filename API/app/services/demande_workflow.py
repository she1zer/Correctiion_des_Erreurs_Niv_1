"""Workflow 12 étapes pour les demandes client."""

ETAPES_STANDARD = [
    ("recue", "Étape 1 : Expression du besoin - vous"),
    ("visite_site", "Étape 2 : Visiter le site - Isitek"),
    ("devis_propose", "Étape 3 : Offre commerciale (devis) - Isitek"),
    ("reception_bc", "Étape 4 : Réception de la commande - vous"),
    ("avance_accompte", "Étape 5 : Avance (accompte) - vous"),
    ("preparation_commande", "Étape 6 : Préparation de la commande - Isitek"),
    ("livraison_bl", "Étape 7 : Livraison de la commande - Isitek"),
    ("depot_facture", "Étape 8 : Facturation - Isitek"),
    ("reglement_cheque", "Étape 9 : Règlement - vous"),
    ("affaire_terminee", "Étape 10 : Affaire terminée - Isitek"),
    ("sav_garantie", "Étape 11 : SAV - garantie - Isitek"),
    ("retour_satisfaction", "Étape 12 : Retour satisfaction - client"),
]

STATUS_TO_STEP = {
    "recue": 1,
    "analyse": 1,
    "visite_site": 2,
    "devis_propose": 3,
    "reception_bc": 4,
    "travaux_planifies": 4,
    "avance_accompte": 5,
    "preparation_commande": 6,
    "livraison_bl": 7,
    "depot_facture": 8,
    "reglement_cheque": 9,
    "affaire_terminee": 10,
    "sav_garantie": 11,
    "retour_satisfaction": 12,
    "termine": 12,
}

STEP_TO_STATUS = {i + 1: s for i, (s, _) in enumerate(ETAPES_STANDARD)}


def parse_skipped(raw: str | None) -> set[int]:
    if not raw:
        return set()
    result = set()
    for part in raw.split(","):
        part = part.strip()
        if part.isdigit():
            result.add(int(part))
    return result


def encode_skipped(skipped: set[int]) -> str:
    return ",".join(str(s) for s in sorted(skipped))


def step_for_status(statut: str) -> int:
    return STATUS_TO_STEP.get(statut, 1)


def next_status(current: str, skipped: set[int]) -> str | None:
    current_step = step_for_status(current)
    for step in range(current_step + 1, len(ETAPES_STANDARD) + 1):
        if step not in skipped:
            return STEP_TO_STATUS[step]
    return None


def label_for_status(statut: str) -> str:
    step = step_for_status(statut)
    if 1 <= step <= len(ETAPES_STANDARD):
        return ETAPES_STANDARD[step - 1][1]
    return statut


def build_resume(demande) -> str:
    lines = [
        "📋 Résumé de votre demande ISITEK",
        f"• Domaine : {demande.domaine}",
        f"• Prestation : {demande.type_prestation}",
        f"• Adresse : {demande.adresse}",
        f"• Description : {demande.description}",
        f"• Étape actuelle : {label_for_status(demande.statut)}",
    ]
    if demande.devis_montant:
        lines.append(f"• Montant devis : {demande.devis_montant:,} FCFA".replace(",", " "))
    if demande.accompte_pourcentage:
        lines.append(f"• Acompte : {demande.accompte_pourcentage}%")
    if demande.garantie_debut and demande.garantie_fin:
        lines.append(
            f"• Garantie : du {demande.garantie_debut} au {demande.garantie_fin}"
            + (f" ({demande.garantie_mois} mois)" if demande.garantie_mois else "")
        )
    return "\n".join(lines)
