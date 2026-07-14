import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../../main.dart' show IsitekColors;
import '../../models/ai_chat_mode.dart';
import '../../services/easy_ai_service.dart';
import '../../services/ai_background_service.dart';

/// Chat IA — choix Easy (base ISITEK) ou Ollama (chat libre).
class EasyChatScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final AiChatMode initialMode;

  const EasyChatScreen({
    super.key,
    this.onBack,
    this.initialMode = AiChatMode.easy,
  });

  @override
  State<EasyChatScreen> createState() => _EasyChatScreenState();
}

class _EasyChatScreenState extends State<EasyChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatBubble> _messages = [];
  List<Map<String, dynamic>> _conversations = [];
  int? _conversationId;
  bool _loading = false;
  bool _loadingConv = true;
  bool _checking = true;
  bool _aiOnline = false;
  bool _ollamaOnline = false;
  String _model = 'qwen3:8b';
  late AiChatMode _mode;
  StreamSubscription? _taskSubscription;
  final Map<String, _ChatBubble> _pendingMessages = {};

  static const _welcomeEasy = _ChatBubble(
    isUser: false,
    isWelcome: true,
    assistantName: 'Easy',
    text:
        'Bonjour ! Je suis Easy, votre assistant IA ISITEK. '
        'Je recherche dans votre base de données (devis, affaires, demandes). '
        'Demandez-moi si vous avez déjà fait un devis pour un client, '
        'ou des infos sur un dossier enregistré. '
        'Comment puis-je vous aider ?',
  );

  static const _welcomeOllama = _ChatBubble(
    isUser: false,
    isWelcome: true,
    assistantName: 'Ollama',
    text:
        'Bonjour ! Mode Ollama — assistant généraliste sans accès à la base ISITEK. '
        'Posez vos questions librement (rédaction, explications techniques, etc.).',
  );

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _checkStatus();
    
    // Écouter les résultats des tâches en arrière-plan
    _taskSubscription = AiBackgroundService.instance.taskResults.listen((result) {
      if (!mounted) return;
      
      final pendingMessage = _pendingMessages[result.taskId];
      if (pendingMessage == null) return;
      
      setState(() {
        _pendingMessages.remove(result.taskId);
        _loading = false;
        
        if (result.success) {
          if (result.conversationId != null) {
            _conversationId = result.conversationId;
          }
          _messages.add(_ChatBubble(
            isUser: false,
            text: result.reply ?? '',
            assistantName: result.mode == AiChatMode.easy ? 'Easy' : 'Ollama',
          ));
          _refreshConversationList();
        } else {
          _messages.add(_ChatBubble(
            isUser: false,
            text: 'Erreur : ${result.error}\n\n'
                'Assurez-vous qu\'Ollama tourne sur le PC :\n'
                'ollama serve\n'
                'ollama pull $_model',
            assistantName: result.mode.label,
          ));
        }
      });
      _scrollToBottom();
    });
    
    if (_mode == AiChatMode.easy) {
      _initConversations();
    } else {
      _resetOllamaSession();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _taskSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final status = await EasyAiService.instance.status();
      if (mounted) {
        setState(() {
          _aiOnline = status['available'] == true;
          _ollamaOnline = status['ollama_online'] == true || _aiOnline;
          _model = status['model'] as String? ?? 'qwen3:8b';
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() {
        _checking = false;
        _aiOnline = false;
        _ollamaOnline = false;
      });
    }
  }

  void _resetOllamaSession() {
    setState(() {
      _loadingConv = false;
      _conversationId = null;
      _messages
        ..clear()
        ..add(_welcomeOllama);
    });
  }

  Future<void> _initConversations() async {
    setState(() => _loadingConv = true);
    try {
      final list = await EasyAiService.instance.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list.cast<Map<String, dynamic>>();
        _loadingConv = false;
      });
      if (_conversations.isNotEmpty) {
        await _loadConversation(_conversations.first['id'] as int);
      } else {
        await _newConversation();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingConv = false;
          _messages
            ..clear()
            ..add(_welcomeEasy);
        });
      }
    }
  }

  Future<void> _switchMode(AiChatMode mode) async {
    if (_mode == mode) return;
    setState(() => _mode = mode);
    if (mode == AiChatMode.easy) {
      await _initConversations();
    } else {
      _resetOllamaSession();
    }
  }

  Future<void> _newConversation() async {
    setState(() => _loadingConv = true);
    try {
      final conv = await EasyAiService.instance.createConversation();
      if (!mounted) return;
      setState(() {
        _conversationId = conv['id'] as int;
        _conversations.insert(0, conv);
        _messages
          ..clear()
          ..add(_welcomeEasy);
        _loadingConv = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingConv = false;
          if (_messages.isEmpty) _messages.add(_welcomeEasy);
        });
      }
    }
  }

  Future<void> _loadConversation(int id) async {
    setState(() => _loadingConv = true);
    try {
      final msgs = await EasyAiService.instance.getMessages(id);
      if (!mounted) return;
      setState(() {
        _conversationId = id;
        _messages
          ..clear()
          ..add(_welcomeEasy);
        for (final m in msgs) {
          if (m is! Map) continue;
          final role = m['role'] as String? ?? '';
          final content = m['content'] as String? ?? '';
          if (content.isEmpty) continue;
          _messages.add(_ChatBubble(isUser: role == 'user', text: content, assistantName: 'Easy'));
        }
        _loadingConv = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (mounted) setState(() => _loadingConv = false);
    }
  }

  Future<void> _deleteCurrentConversation() async {
    final id = _conversationId;
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la conversation ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await EasyAiService.instance.deleteConversation(id);
      if (!mounted) return;
      setState(() => _conversations.removeWhere((c) => c['id'] == id));
      if (_conversations.isNotEmpty) {
        await _loadConversation(_conversations.first['id'] as int);
      } else {
        await _newConversation();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
      }
    }
  }

  List<Map<String, String>> _ollamaHistoryBeforeSend() {
    return _messages
        .where((m) => !m.isWelcome)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading || (_mode == AiChatMode.easy && _loadingConv)) return;

    final online = _mode == AiChatMode.easy ? _aiOnline : _ollamaOnline;
    if (!online) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mode == AiChatMode.easy
              ? 'Easy indisponible — vérifiez Ollama sur le PC'
              : 'Ollama indisponible — lancez ollama serve sur le PC'),
        ),
      );
      return;
    }

    setState(() {
      _messages.add(_ChatBubble(isUser: true, text: text));
      _loading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Lancer la tâche en arrière-plan
    final history = _mode == AiChatMode.ollama 
        ? _ollamaHistoryBeforeSend().cast<Map<String, String>>() 
        : <Map<String, String>>[];
    
    final taskId = AiBackgroundService.instance.startAiTask(
      message: text,
      mode: _mode,
      history: history,
      conversationId: _conversationId,
    );

    // Stocker le message en attente avec le taskId
    _pendingMessages[taskId] = _ChatBubble(isUser: true, text: text);
  }

  Future<void> _refreshConversationList() async {
    try {
      final list = await EasyAiService.instance.listConversations();
      if (mounted) setState(() => _conversations = list.cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showConversationPicker() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_comment_outlined, color: IsitekColors.green),
              title: const Text('Nouvelle conversation'),
              onTap: () {
                Navigator.pop(ctx);
                _newConversation();
              },
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _conversations.length,
                itemBuilder: (_, i) {
                  final c = _conversations[i];
                  final id = c['id'] as int;
                  final title = c['title'] as String? ?? 'Conversation';
                  final selected = id == _conversationId;
                  return ListTile(
                    leading: Icon(
                      selected ? Icons.chat_bubble : Icons.chat_bubble_outline,
                      color: selected ? IsitekColors.green : null,
                    ),
                    title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${c['message_count'] ?? 0} message(s)'),
                    trailing: selected ? const Icon(Icons.check, color: IsitekColors.green) : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      if (!selected) _loadConversation(id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _modeOnline => _mode == AiChatMode.easy ? _aiOnline : _ollamaOnline;

  @override
  Widget build(BuildContext context) {
    final isEasy = _mode == AiChatMode.easy;

    return Column(
      children: [
        Material(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    if (widget.onBack != null)
                      IconButton(
                        tooltip: 'Retour',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onBack,
                      ),
                    if (isEasy) ...[
                      IconButton(
                        tooltip: 'Conversations',
                        icon: const Icon(Icons.history),
                        onPressed: _showConversationPicker,
                      ),
                      Expanded(
                        child: Text(
                          _conversations
                                  .where((c) => c['id'] == _conversationId)
                                  .map((c) => c['title'] as String? ?? 'Easy')
                                  .firstOrNull ??
                              'Easy',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Nouvelle conversation',
                        icon: const Icon(Icons.add),
                        onPressed: _newConversation,
                      ),
                      if (_conversationId != null)
                        IconButton(
                          tooltip: 'Supprimer',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: _deleteCurrentConversation,
                        ),
                    ] else
                      const Expanded(
                        child: Text(
                          'Ollama — chat libre',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                  ],
                ),
                SegmentedButton<AiChatMode>(
                  segments: const [
                    ButtonSegment(
                      value: AiChatMode.easy,
                      label: Text('Easy'),
                      icon: Icon(Icons.storage_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: AiChatMode.ollama,
                      label: Text('Ollama'),
                      icon: Icon(Icons.smart_toy_outlined, size: 18),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => _switchMode(s.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!_checking)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: _modeOnline ? IsitekColors.greenSoft : Colors.orange.shade50,
            child: Row(
              children: [
                Icon(
                  _modeOnline ? Icons.check_circle : Icons.warning_amber_rounded,
                  color: _modeOnline ? IsitekColors.green : Colors.orange,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _modeOnline
                        ? (isEasy
                            ? 'Easy en ligne — $_model · base ISITEK'
                            : 'Ollama en ligne — $_model · chat libre')
                        : (isEasy
                            ? 'Easy hors ligne — lancez ollama serve sur le PC'
                            : 'Ollama hors ligne — lancez ollama serve sur le PC'),
                    style: TextStyle(
                      fontSize: 12,
                      color: _modeOnline ? IsitekColors.greenDark : Colors.orange.shade800,
                    ),
                  ),
                ),
                if (!_modeOnline)
                  TextButton(onPressed: _checkStatus, child: const Text('Réessayer')),
              ],
            ),
          ),
        Expanded(
          child: (isEasy && _loadingConv)
              ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_loading && index == _messages.length) {
                      return _TypingIndicator(mode: _mode);
                    }
                    return _MessageBubble(message: _messages[index]);
                  },
                ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: isEasy ? 'Écrire à Easy…' : 'Écrire à Ollama…',
                    filled: true,
                    fillColor: IsitekColors.bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: (_loading || (isEasy && _loadingConv)) ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: IsitekColors.green,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble {
  final bool isUser;
  final String text;
  final bool isWelcome;
  final String assistantName;

  const _ChatBubble({
    required this.isUser,
    required this.text,
    this.isWelcome = false,
    this.assistantName = 'Easy',
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatBubble message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? IsitekColors.green : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: IsitekColors.greenSoft),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text(
                      message.assistantName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: IsitekColors.green,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: message.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Réponse copiée'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.copy,
                        size: 14,
                        color: IsitekColors.green,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isUser ? Colors.white : IsitekColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final AiChatMode mode;
  const _TypingIndicator({required this.mode});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: IsitekColors.greenSoft),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: IsitekColors.green),
            ),
            const SizedBox(width: 10),
            Text(
              '${mode.label} réfléchit…',
              style: const TextStyle(fontSize: 12, color: IsitekColors.textSoft),
            ),
          ],
        ),
      ),
    );
  }
}
