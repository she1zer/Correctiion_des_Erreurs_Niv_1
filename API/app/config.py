from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # XAMPP MariaDB : utilisateur root, mot de passe vide par défaut
    database_url: str = "mysql+pymysql://root@127.0.0.1:3306/isitek?charset=utf8mb4"
    secret_key: str = "isitek-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 1440

    # Configuration email IMAP (réception des demandes clients)
    imap_host: str = ""
    imap_port: int = 993
    imap_user: str = ""
    imap_password: str = ""
    imap_folder: str = "INBOX"

    # Recherche produits (SerpApi recommandé — Google Shopping)
    serp_api_key: str = ""
    # Optionnel : Brave Search API (complément)
    brave_api_key: str = ""

    # Isi — Google Gemini (prioritaire), OpenAI ou Ollama (secours)
    gemini_api_key: str = ""
    gemini_model: str = "gemini-2.0-flash"
    gemini_timeout_seconds: int = 45
    openai_api_key: str = ""
    openai_model: str = "gpt-4o-mini"
    openai_timeout_seconds: int = 45
    ollama_base_url: str = "http://127.0.0.1:11434"
    ollama_model: str = "qwen3:8b"
    ollama_timeout_seconds: int = 90

    class Config:
        env_file = ".env"


settings = Settings()
