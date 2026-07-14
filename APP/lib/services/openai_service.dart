import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service client pour OpenAI API (via HTTP direct).
class OpenAiService {
  static final OpenAiService instance = OpenAiService._();
  OpenAiService._();

  static const String _baseUrl = 'https://api.openai.com/v1';
  static const String _model = 'gpt-4o-mini';

  /// Envoie un message à ChatGPT et retourne la réponse
  Future<String> chat(String message, {List<Map<String, String>> history = const []}) async {
    try {
      final messages = <Map<String, String>>[
        {
          'role': 'system',
          'content': 'Tu es un assistant IA pour ISITEK, une entreprise d\'expertise industrielle. Aide les utilisateurs avec leurs demandes de manière professionnelle et précise.',
        },
      ];

      // Ajouter l'historique
      for (final entry in history) {
        if (entry['user'] != null && entry['user']!.isNotEmpty) {
          messages.add({'role': 'user', 'content': entry['user']!});
        }
        if (entry['assistant'] != null && entry['assistant']!.isNotEmpty) {
          messages.add({'role': 'assistant', 'content': entry['assistant']!});
        }
      }

      // Ajouter le message actuel
      messages.add({'role': 'user', 'content': message});

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Erreur API OpenAI: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur OpenAI: $e');
    }
  }

  /// Analyse un email et retourne des informations structurées
  Future<Map<String, dynamic>> analyzeEmail({
    required String body,
    String subject = '',
    String fromAddress = '',
  }) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': '''Tu es un assistant qui analyse les emails. Retourne UN SEUL objet JSON valide avec les champs suivants:
- summary: résumé de l'email en 1-2 phrases
- priority: "high", "medium", ou "low"
- category: catégorie de l'email (ex: "demande_devis", "support", "information", etc.)
- action_required: true si une action est requise, false sinon
- suggested_response: suggestion de réponse courte si applicable'''
        },
        {
          'role': 'user',
          'content': 'Sujet: $subject\nDe: $fromAddress\n\nContenu: $body'
        },
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.3,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        throw Exception('Erreur API OpenAI: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur analyse email: $e');
    }
  }

  /// Génère une suggestion de réponse
  Future<String> generateResponse({
    required String originalMessage,
    required String context,
  }) async {
    try {
      final messages = [
        {
          'role': 'system',
          'content': 'Tu es un assistant professionnel pour ISITEK. Génère des réponses polies et professionnelles.'
        },
        {
          'role': 'user',
          'content': 'Contexte: $context\n\nMessage original: $originalMessage\n\nGénère une réponse appropriée.'
        },
      ];

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('Erreur API OpenAI: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur génération réponse: $e');
    }
  }
}
