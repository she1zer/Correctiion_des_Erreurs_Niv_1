"""Compatibilité — préférez app.services.isi_ai_service."""
from app.services.isi_ai_service import (  # noqa: F401
    analyze_email_with_isi,
    chat_isi,
    get_isi_model_label,
    get_isi_provider,
    isi_available,
    list_ollama_models,
    ollama_available,
)

list_models = list_ollama_models
