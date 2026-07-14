/// Configuration de l'API ISITEK Connect.
///
/// Sur téléphone Android (même Wi-Fi que le PC) :
/// 1. PowerShell sur le PC : `ipconfig` → Adresse IPv4 (ex: 192.168.1.XXX)
/// 2. Remplacez baseUrl ci-dessous par http://VOTRE_IP:8000
/// 3. Lancez l'API : `cd Isitek_api && python run.py`
/// 4. Autorisez le port 8000 dans le pare-feu Windows si besoin
class ApiConfig {
  /// IP locale du PC où tourne l'API (python run.py)
  static const String baseUrl = 'http://192.168.1.11:8000';

  /// Clé API OpenAI pour les fonctionnalités IA
  /// IMPORTANT: En production, utilisez des variables d'environnement ou un fichier de configuration sécurisé
  static const String openAiApiKey =
      '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';
}
