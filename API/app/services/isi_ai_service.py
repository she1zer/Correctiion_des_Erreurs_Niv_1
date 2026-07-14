import json
import re

import httpx

from app.config import settings

OLLAMA_RAW_SYSTEM_PROMPT = """Tu es un assistant IA généraliste, propulsé par Ollama.
Réponds en français de manière claire, professionnelle et utile.
Dans ce mode tu n'as PAS accès à la base de données ISITEK — ne prétends pas consulter des devis ou dossiers."""

ISI_SYSTEM_PROMPT = """Tu es Easy, l'assistant IA officiel d'ISITEK SARL (Côte d'Ivoire), propulsé par Ollama.
ISITEK est une entreprise d'études, ingénierie, réalisation, formation et expertise industrielle.

Tu aides les administrateurs et techniciens ISITEK en répondant UNIQUEMENT à partir des données
de leur base ISITEK (devis proforma, affaires, demandes clients) fournies avec chaque message.

Règles STRICTES :
- Réponds TOUJOURS en français
- Utilise SEULEMENT les informations du bloc « DONNÉES ISITEK » — ne invente jamais de devis, clients ou montants
- Si aucun enregistrement correspond : dis clairement « Aucun devis / affaire trouvé pour … »
- Si des enregistrements existent : confirme (ex. « Oui, vous avez déjà fait un devis pour … ») et donne numéro, date, client, montant, contact, objet
- Sois professionnel, structuré (listes si plusieurs résultats) et concis
- Ne donne pas de conseils génériques hors base de données"""

# Pas de limite de temps pour Ollama (qwen3 peut mettre 1-2 min au 1er appel)
_OLLAMA_TIMEOUT = None


def _strip_thinking(text: str) -> str:
    text = re.sub(
        r"Thinking\.\.\..*?\.\.\.done thinking\.\s*",
        "",
        text,
        flags=re.DOTALL | re.IGNORECASE,
    )
    text = re.sub(
        r"<think>.*?</think>",
        "",
        text,
        flags=re.DOTALL | re.IGNORECASE,
    )
    return text.strip()


def gemini_configured() -> bool:
    return bool(settings.gemini_api_key.strip())


def openai_configured() -> bool:
    return bool(settings.openai_api_key.strip())


def ollama_available() -> bool:
    try:
        response = httpx.get(f"{settings.ollama_base_url}/api/tags", timeout=8)
        return response.status_code == 200
    except Exception:
        return False


def isi_available() -> bool:
    return ollama_available() or gemini_configured() or openai_configured()


def get_isi_provider() -> str:
    if ollama_available():
        return "ollama"
    if gemini_configured():
        return "gemini"
    if openai_configured():
        return "openai"
    return "none"


def get_isi_model_label() -> str:
    if ollama_available():
        return settings.ollama_model
    if gemini_configured():
        return settings.gemini_model
    if openai_configured():
        return settings.openai_model
    return settings.ollama_model


def list_ollama_models() -> list[str]:
    try:
        response = httpx.get(f"{settings.ollama_base_url}/api/tags", timeout=8)
        if response.status_code != 200:
            return []
        return [m.get("name", "") for m in response.json().get("models", [])]
    except Exception:
        return []


def _build_openai_history(
    messages: list[dict],
    user_message: str,
    system_prompt: str = ISI_SYSTEM_PROMPT,
) -> list[dict]:
    history = [{"role": "system", "content": system_prompt}]
    for msg in messages[-20:]:
        role = msg.get("role", "user")
        if role in ("user", "assistant"):
            history.append({"role": role, "content": msg.get("content", "")})
    history.append({"role": "user", "content": user_message})
    return history


def _chat_ollama(
    messages: list[dict],
    user_message: str,
    system_prompt: str = ISI_SYSTEM_PROMPT,
) -> str:
    history = _build_openai_history(messages, user_message, system_prompt=system_prompt)
    payload: dict = {
        "model": settings.ollama_model,
        "messages": history,
        "stream": False,
        "options": {"temperature": 0.6, "num_predict": 768},
    }
    if "qwen" in settings.ollama_model.lower():
        payload["think"] = False

    response = httpx.post(
        f"{settings.ollama_base_url}/api/chat",
        json=payload,
        timeout=_OLLAMA_TIMEOUT,
    )
    response.raise_for_status()
    data = response.json()
    content = data.get("message", {}).get("content", "")
    if not content and data.get("response"):
        content = data["response"]
    return _strip_thinking(content) or "Je n'ai pas pu générer de réponse."


def _build_gemini_contents(messages: list[dict], user_message: str) -> list[dict]:
    contents: list[dict] = []
    for msg in messages[-20:]:
        role = msg.get("role", "user")
        if role not in ("user", "assistant"):
            continue
        contents.append(
            {
                "role": "user" if role == "user" else "model",
                "parts": [{"text": msg.get("content", "")}],
            }
        )
    contents.append({"role": "user", "parts": [{"text": user_message}]})
    return contents


def _chat_gemini(messages: list[dict], user_message: str) -> str:
    url = f"https://generativelanguage.googleapis.com/v1beta/models/{settings.gemini_model}:generateContent"
    response = httpx.post(
        url,
        headers={
            "Content-Type": "application/json",
            "x-goog-api-key": settings.gemini_api_key,
        },
        json={
            "systemInstruction": {"parts": [{"text": ISI_SYSTEM_PROMPT}]},
            "contents": _build_gemini_contents(messages, user_message),
            "generationConfig": {"temperature": 0.6, "maxOutputTokens": 1024},
        },
        timeout=settings.gemini_timeout_seconds,
    )
    response.raise_for_status()
    candidates = response.json().get("candidates") or []
    if not candidates:
        raise RuntimeError("Gemini : aucune réponse")
    parts = candidates[0].get("content", {}).get("parts") or []
    text = "".join(p.get("text", "") for p in parts)
    return _strip_thinking(text) or "Je n'ai pas pu générer de réponse."


def _chat_openai(messages: list[dict], user_message: str) -> str:
    history = _build_openai_history(messages, user_message)
    response = httpx.post(
        "https://api.openai.com/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {settings.openai_api_key}",
            "Content-Type": "application/json",
        },
        json={
            "model": settings.openai_model,
            "messages": history,
            "temperature": 0.6,
            "max_tokens": 800,
        },
        timeout=settings.openai_timeout_seconds,
    )
    response.raise_for_status()
    content = response.json()["choices"][0]["message"]["content"]
    return _strip_thinking(content) or "Je n'ai pas pu générer de réponse."


def chat_isi(
    messages: list[dict],
    user_message: str,
    db_context: str | None = None,
) -> tuple[str, str]:
    """Priorité : Ollama (local) → Gemini → OpenAI."""
    if db_context is not None:
        from app.services.easy_db_context_service import augment_message_with_db_context

        user_message = augment_message_with_db_context(user_message, db_context)
    errors: list[str] = []
    if ollama_available():
        try:
            return _chat_ollama(messages, user_message), settings.ollama_model
        except Exception as e:
            errors.append(f"Ollama: {e}")

    if gemini_configured():
        try:
            return _chat_gemini(messages, user_message), settings.gemini_model
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 429 and ollama_available():
                try:
                    return _chat_ollama(messages, user_message), settings.ollama_model
                except Exception as ollama_err:
                    errors.append(f"Gemini quota + Ollama: {ollama_err}")
            errors.append(f"Gemini ({e.response.status_code})")
        except Exception as e:
            errors.append(f"Gemini: {e}")

    if openai_configured():
        try:
            return _chat_openai(messages, user_message), settings.openai_model
        except Exception as e:
            errors.append(f"OpenAI: {e}")

    hint = (
        "Démarrez Ollama sur le PC : ollama serve  "
        "(modèle : ollama pull qwen3:8b)"
    )
    if errors:
        raise RuntimeError(f"Easy indisponible ({'; '.join(errors)}). {hint}")
    raise RuntimeError(f"Easy indisponible. {hint}")


def chat_ollama_raw(messages: list[dict], user_message: str) -> tuple[str, str]:
    """Chat Ollama libre, sans contexte base ISITEK."""
    if not ollama_available():
        raise RuntimeError(
            "Ollama indisponible. Démarrez Ollama sur le PC : ollama serve "
            f"(modèle : ollama pull {settings.ollama_model})"
        )
    return _chat_ollama(messages, user_message, system_prompt=OLLAMA_RAW_SYSTEM_PROMPT), settings.ollama_model


def analyze_email_with_isi(subject: str, body: str, from_address: str = "") -> dict | None:
    prompt = f"""Analyse cet email client ISITEK et réponds UNIQUEMENT avec un JSON valide (sans markdown) :
{{
  "references": ["REF1", "REF2"],
  "client_nom": "nom entreprise client ou null",
  "contact": "nom contact ou null",
  "client_da": "numéro DA si présent ou null",
  "resume": "résumé en 2 phrases"
}}

Email de : {from_address}
Objet : {subject}
Contenu :
{body[:5000]}"""

    try:
        raw, _ = chat_isi([], prompt)
        raw = raw.strip()
        if raw.startswith("```"):
            raw = re.sub(r"^```(?:json)?\s*", "", raw)
            raw = re.sub(r"\s*```$", "", raw)
        match = re.search(r"\{.*\}", raw, re.DOTALL)
        if match:
            return json.loads(match.group())
    except Exception:
        return None
    return None
