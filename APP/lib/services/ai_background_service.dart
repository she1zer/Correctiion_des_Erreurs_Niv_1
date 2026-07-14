import 'dart:async';
import 'package:flutter/foundation.dart';
import 'easy_ai_service.dart';
import 'notification_service.dart';
import '../models/ai_chat_mode.dart';

/// Service pour exécuter les tâches IA en arrière-plan
/// et notifier l'utilisateur quand la réponse est prête
class AiBackgroundService {
  static final AiBackgroundService instance = AiBackgroundService._();
  AiBackgroundService._();

  final Map<String, _AiTask> _activeTasks = {};
  final StreamController<_AiTaskResult> _resultController =
      StreamController<_AiTaskResult>.broadcast();

  Stream<_AiTaskResult> get taskResults => _resultController.stream;

  /// Lance une requête IA en arrière-plan
  /// Retourne un taskId unique pour suivre la tâche
  String startAiTask({
    required String message,
    required AiChatMode mode,
    List<Map<String, String>> history = const [],
    int? conversationId,
  }) {
    final taskId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final task = _AiTask(
      id: taskId,
      message: message,
      mode: mode,
      history: history,
      conversationId: conversationId,
      startTime: DateTime.now(),
    );

    _activeTasks[taskId] = task;

    // Exécuter la tâche en arrière-plan
    _executeTask(task).then((result) {
      _activeTasks.remove(taskId);
      _resultController.add(result);
      
      // Notifier l'utilisateur
      _notifyUser(result);
    }).catchError((error) {
      _activeTasks.remove(taskId);
      final errorResult = _AiTaskResult(
        taskId: taskId,
        success: false,
        error: error.toString(),
        mode: mode,
      );
      _resultController.add(errorResult);
    });

    return taskId;
  }

  Future<_AiTaskResult> _executeTask(_AiTask task) async {
    try {
      Map<String, dynamic> data;
      
      if (task.mode == AiChatMode.easy) {
        data = await EasyAiService.instance.chat(
          task.message,
          conversationId: task.conversationId,
        );
      } else {
        data = await EasyAiService.instance.ollamaChat(
          task.message,
          history: task.history,
        );
      }

      final reply = data['reply'] as String? ?? '';
      final convId = data['conversation_id'] as int?;

      return _AiTaskResult(
        taskId: task.id,
        success: true,
        reply: reply,
        conversationId: convId,
        mode: task.mode,
      );
    } catch (e) {
      throw e;
    }
  }

  Future<void> _notifyUser(_AiTaskResult result) async {
    if (!result.success || result.reply == null) return;

    final modeName = result.mode == AiChatMode.easy ? 'Easy' : 'Ollama';
    final title = '$modeName a répondu';
    final reply = result.reply!;
    final body = reply.length > 50
        ? '${reply.substring(0, 50)}...'
        : reply;

    await NotificationService.instance.showNotification(
      title: title,
      body: body,
      payload: result.taskId,
    );
  }

  /// Annuler une tâche en cours
  void cancelTask(String taskId) {
    _activeTasks.remove(taskId);
  }

  /// Obtenir le statut d'une tâche
  bool isTaskActive(String taskId) {
    return _activeTasks.containsKey(taskId);
  }

  void dispose() {
    _resultController.close();
  }
}

class _AiTask {
  final String id;
  final String message;
  final AiChatMode mode;
  final List<Map<String, String>> history;
  final int? conversationId;
  final DateTime startTime;

  _AiTask({
    required this.id,
    required this.message,
    required this.mode,
    required this.history,
    this.conversationId,
    required this.startTime,
  });
}

class _AiTaskResult {
  final String taskId;
  final bool success;
  final String? reply;
  final int? conversationId;
  final String? error;
  final AiChatMode mode;

  _AiTaskResult({
    required this.taskId,
    required this.success,
    this.reply,
    this.conversationId,
    this.error,
    required this.mode,
  });
}
