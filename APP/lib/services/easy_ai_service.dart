import '../services/api_service.dart';

/// Service client pour Easy (Ollama) — assistant IA via backend.
class EasyAiService {
  static final EasyAiService instance = EasyAiService._();
  EasyAiService._();

  Future<Map<String, dynamic>> status() async {
    return ApiService.instance.getOne('/api/ai/status');
  }

  Future<List<dynamic>> listConversations() async {
    return ApiService.instance.get('/api/ai/conversations');
  }

  Future<Map<String, dynamic>> createConversation() async {
    return ApiService.instance.post('/api/ai/conversations', {});
  }

  Future<List<dynamic>> getMessages(int conversationId) async {
    return ApiService.instance.get('/api/ai/conversations/$conversationId/messages');
  }

  Future<void> deleteConversation(int conversationId) async {
    await ApiService.instance.delete('/api/ai/conversations/$conversationId');
  }

  Future<Map<String, dynamic>> chat(
    String message, {
    List<Map<String, String>> history = const [],
    int? conversationId,
  }) async {
    return ApiService.instance.post(
      '/api/ai/chat',
      {
        'message': message,
        'history': history,
        if (conversationId != null) 'conversation_id': conversationId,
      },
      timeout: const Duration(minutes: 10),
    );
  }

  /// Chat Ollama libre (sans contexte base de données).
  Future<Map<String, dynamic>> ollamaChat(
    String message, {
    List<Map<String, String>> history = const [],
  }) async {
    return ApiService.instance.post(
      '/api/ai/ollama-chat',
      {
        'message': message,
        'history': history,
      },
      timeout: const Duration(minutes: 10),
    );
  }

  Future<Map<String, dynamic>> analyzeEmail({
    required String body,
    String subject = '',
    String fromAddress = '',
  }) async {
    return ApiService.instance.post(
      '/api/ai/analyze-email',
      {
        'subject': subject,
        'body': body,
        'from_address': fromAddress,
      },
      timeout: const Duration(minutes: 10),
    );
  }
}
