import 'dart:async';

import 'package:flutter/material.dart';

import '../../main.dart' show IsitekColors;
import '../../services/api_service.dart';

class StaffMessageService extends ChangeNotifier {
  static final StaffMessageService instance = StaffMessageService._();
  StaffMessageService._();

  List<dynamic> _messages = [];
  Timer? _timer;
  int? _activeTechnicienId;
  bool _loading = false;

  List<dynamic> get messages => _messages;
  bool get loading => _loading;

  void startPolling({int? technicienId}) {
    _activeTechnicienId = technicienId;
    _timer?.cancel();
    fetchMessages();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => fetchMessages());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> fetchMessages() async {
    try {
      final user = ApiService.instance.currentUser;
      if (user == null) return;
      final path = user.isAdmin
          ? '/api/staff-messages/?technicien_id=$_activeTechnicienId'
          : '/api/staff-messages/';
      if (user.isAdmin && _activeTechnicienId == null) return;
      _messages = await ApiService.instance.get(path);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> sendMessage(String content, {int? technicienId}) async {
    await ApiService.instance.post('/api/staff-messages/', {
      'content': content,
      if (technicienId != null) 'technicien_id': technicienId,
    });
    await fetchMessages();
  }
}

class StaffChatScreen extends StatefulWidget {
  final int? technicienId;
  final String title;

  const StaffChatScreen({super.key, this.technicienId, required this.title});

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    StaffMessageService.instance.startPolling(technicienId: widget.technicienId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    StaffMessageService.instance.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await StaffMessageService.instance.sendMessage(text, technicienId: widget.technicienId);
    if (mounted) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListenableBuilder(
              listenable: StaffMessageService.instance,
              builder: (context, _) {
                final list = StaffMessageService.instance.messages;
                WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('Démarrez la conversation', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, index) {
                    final msg = list[index];
                    final isMine = user?.isAdmin == true
                        ? msg['sender_role'] == 'admin'
                        : msg['sender_role'] == 'technicien';
                    return Align(
                      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                        decoration: BoxDecoration(
                          color: isMine ? IsitekColors.greenDark : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMine ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMine ? Radius.zero : const Radius.circular(16),
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMine)
                              Text(
                                '${msg['sender_prenom'] ?? ''} ${msg['sender_nom'] ?? ''}'.trim(),
                                style: TextStyle(fontSize: 10, color: isMine ? Colors.white70 : IsitekColors.green, fontWeight: FontWeight.bold),
                              ),
                            Text(
                              msg['content'] ?? '',
                              style: TextStyle(color: isMine ? Colors.white : IsitekColors.textDark, fontSize: 13.5),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message...',
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: IsitekColors.green,
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: _send,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AdminStaffInboxScreen extends StatefulWidget {
  const AdminStaffInboxScreen({super.key});

  @override
  State<AdminStaffInboxScreen> createState() => _AdminStaffInboxScreenState();
}

class _AdminStaffInboxScreenState extends State<AdminStaffInboxScreen> {
  List<dynamic> _conversations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.instance.get('/api/staff-messages/conversations');
      if (mounted) setState(() { _conversations = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Messages équipe', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: IsitekColors.green,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: IsitekColors.green))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _conversations.length,
              itemBuilder: (context, i) {
                final c = _conversations[i];
                final name = '${c['technicien_prenom']} ${c['technicien_nom']}';
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: IsitekColors.greenSoft,
                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'T', style: const TextStyle(color: IsitekColors.greenDark, fontWeight: FontWeight.bold)),
                    ),
                    title: Text(name.trim(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c['poste'] != null) Text(c['poste'], style: const TextStyle(fontSize: 11, color: IsitekColors.green)),
                        Text(c['last_message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right, color: IsitekColors.green),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StaffChatScreen(
                            technicienId: c['technicien_id'],
                            title: name.trim(),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

class TechAdminMessagesScreen extends StatelessWidget {
  const TechAdminMessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.instance.currentUser;
    return StaffChatScreen(
      title: 'Administration ISITEK',
      technicienId: user?.isAdmin == true ? null : user?.id,
    );
  }
}
