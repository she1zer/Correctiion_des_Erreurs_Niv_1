/// Mode de chat IA : Easy (base ISITEK) ou Ollama (chat libre).
enum AiChatMode {
  easy,
  ollama,
}

extension AiChatModeLabel on AiChatMode {
  String get label => this == AiChatMode.easy ? 'Easy' : 'Ollama';

  String get subtitle => this == AiChatMode.easy
      ? 'Recherche dans la base ISITEK (devis, affaires, demandes)'
      : 'Chat libre avec Ollama, sans accès à la base de données';
}
