import re

IGNORED = {
    "HTTP", "HTTPS", "MAIL", "INFO", "EMAIL", "DEVIS", "DA", "REF",
    "RCCM", "CFA", "BICICI", "ISITEK", "SARL", "CMDE", "DATE",
}


def extract_references(text: str) -> list[str]:
    if not text:
        return []

    refs: set[str] = set()
    upper = text.upper()

    explicit_patterns = [
        r"(?:REF|RÉF|REFERENCE|RÉFÉRENCE|ARTICLE|CODE)[:\s#\-]*([A-Z0-9][A-Z0-9\-_/\.]{2,25})",
        r"(?:N°|NO|NUM(?:ÉRO)?)[:\s]*([A-Z0-9][A-Z0-9\-_/\.]{2,25})",
    ]
    for pattern in explicit_patterns:
        for match in re.finditer(pattern, upper, re.IGNORECASE):
            ref = _clean_ref(match.group(1))
            if ref:
                refs.add(ref)

    generic_patterns = [
        r"\b([A-Z]{2,5}[0-9]{3,8}[A-Z0-9]*)\b",
        r"\b([A-Z]{2,}[0-9]{2,}[A-Z0-9\-]{0,8})\b",
        r"\b([0-9]{2,}[A-Z]{2,}[A-Z0-9\-]{0,8})\b",
    ]
    for pattern in generic_patterns:
        for match in re.finditer(pattern, upper):
            ref = _clean_ref(match.group(1))
            if ref:
                refs.add(ref)

    return sorted(refs)


def extract_client_info(text: str, subject: str = "", from_address: str = "") -> dict:
    info: dict[str, str | None] = {
        "client_nom": None,
        "contact": None,
        "client_da": None,
    }

    da_match = re.search(
        r"(?:DA|D\.A\.|DEMANDE\s+D['']ACHAT)[:\s#\-]*([A-Z0-9\-/]{4,20})",
        f"{subject}\n{text}",
        re.IGNORECASE,
    )
    if da_match:
        info["client_da"] = da_match.group(1).upper()

    company_match = re.search(
        r"(?:SOCIÉTÉ|SOCIETE|ENTREPRISE|CLIENT|RAISON\s+SOCIALE)[:\s\-]*([^\n\r]{3,80})",
        text,
        re.IGNORECASE,
    )
    if company_match:
        info["client_nom"] = company_match.group(1).strip().title()

    contact_match = re.search(
        r"(?:CONTACT|NOM|ATTENTION|A\/L)[:\s\-]*([A-ZÀÂÄÉÈÊËÏÎÔÙÛÜÇ\s\-]{3,40})",
        text,
        re.IGNORECASE,
    )
    if contact_match:
        info["contact"] = contact_match.group(1).strip().upper()

    if not info["client_nom"] and from_address:
        local = from_address.split("@")[0]
        if "." in local:
            parts = local.split(".")
            info["contact"] = parts[0].upper()
        domain = from_address.split("@")[-1].split(".")[0]
        if domain not in {"gmail", "yahoo", "hotmail", "outlook"}:
            info["client_nom"] = domain.replace("-", " ").title()

    return info


def _clean_ref(raw: str) -> str | None:
    ref = raw.strip(" .,;:-_/\\").upper()
    if len(ref) < 4 or len(ref) > 30:
        return None
    if ref in IGNORED:
        return None
    if ref.isdigit():
        return None
    if not re.search(r"[A-Z]", ref) or not re.search(r"[0-9]", ref):
        if len(ref) < 6:
            return None
    return ref
