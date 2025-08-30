import 'package:flutter/material.dart';
import 'package:frontend/services/message_service.dart';

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _conversations = const [];

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await MessageService.instance.getConversations();
      final list = (res['conversations'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      setState(() => _conversations = list);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conversations')),
      body: _loading && _conversations.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _conversations.length,
                itemBuilder: (context, index) {
                  final c = _conversations[index];
                  final user = (c['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
                  final last = (c['lastMessage'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
                  final unread = (c['unreadCount'] is num) ? (c['unreadCount'] as num).toInt() : 0;
                  final name = (user['name'] ?? 'Unknown').toString();
                  final phone = (user['phone'] ?? '').toString();
                  final preview = (last['content'] ?? '').toString();
                  final ts = (last['timestamp'] ?? '').toString();
                  return ListTile(
                    leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
                    title: Text(name),
                    subtitle: Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(ts.isNotEmpty ? ts.split('T').first : ''),
                        if (unread > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                            child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).pushNamed(
                      '/messages/chat',
                      arguments: {'receiverId': (user['_id'] ?? '').toString(), 'name': name, 'phone': phone},
                    ),
                  );
                },
              ),
            ),
    );
  }
}


