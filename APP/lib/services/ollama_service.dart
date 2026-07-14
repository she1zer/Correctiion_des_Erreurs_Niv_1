import '../services/easy_ai_service.dart';

/// Client Ollama via l'API ISITEK (proxy vers le serveur Ollama du PC).
class OllamaService {
  static final OllamaService instance = OllamaService._();
  OllamaService._();

  Future<String> ask(String prompt, {List<Map<String, String>> history = const []}) async {
    final data = await EasyAiService.instance.ollamaChat(prompt, history: history);
    return data['reply'] as String? ?? '';
  }
}
