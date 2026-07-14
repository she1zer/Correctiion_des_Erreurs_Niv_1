from app.schemas.devis import ProduitLigne


def compute_line_totals(ligne: ProduitLigne) -> tuple[float, float, float]:
    brut = ligne.quantite * ligne.prix_unitaire_ht
    remise = brut * (ligne.remise_pourcentage / 100)
    net = brut - remise
    return brut, remise, net


def compute_devis_totals(lignes: list[ProduitLigne]) -> tuple[int, int, int]:
    total_brut = 0.0
    total_remise = 0.0
    for ligne in lignes:
        brut, remise, _ = compute_line_totals(ligne)
        total_brut += brut
        total_remise += remise
    total_net = total_brut - total_remise
    return int(round(total_brut)), int(round(total_remise)), int(round(total_net))


def generate_numero_devis(existing_count: int) -> str:
    from datetime import datetime

    year = datetime.now().strftime("%y")
    seq = existing_count + 1
    return f"{year}FP{seq:04d}"
