import 'package:flutter/material.dart';
import 'package:frontend/services/message_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  bool _loading = false;
  String? _error;
  late final String receiverId;
  String? _currentUserId;
  List<Map<String, dynamic>> _messages = const [];

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('userId');
    await MessageService.instance.connect(_currentUserId ?? '');
    MessageService.instance.onNewMessage((msg) {
      setState(() {
        _messages = List<Map<String, dynamic>>.from(_messages)..add(msg);
      });
    });
  }

  Future<void> _loadHistory() async {
    setState(() => _loading = true);
    try {
      final res = await MessageService.instance.getConversation(_currentUserId ?? '', receiverId);
      final list = (res['messages'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      setState(() => _messages = list);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final order = <String, dynamic>{};
    if (_categoryController.text.trim().isNotEmpty) order['category'] = _categoryController.text.trim();
    if (_quantityController.text.trim().isNotEmpty) order['quantity'] = _quantityController.text.trim();
    if (_addressController.text.trim().isNotEmpty) order['deliveryAddress'] = _addressController.text.trim();

    try {
      final res = await MessageService.instance.sendMessage(
        receiverId,
        text,
        orderDetails: order.isEmpty ? null : order,
      );
      final msg = (res['message'] as Map?)?.cast<String, dynamic>();
      if (msg != null) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(_messages)..add(msg);
          _messageController.clear();
        });
      }
      // also via socket for realtime to receiver
      MessageService.instance.sendMessageSocket({
        'receiverId': receiverId,
        'senderId': _currentUserId,
        'content': text,
        if (order.isNotEmpty) 'orderDetails': order,
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    receiverId = (args?['receiverId'] ?? '').toString();
    _init().then((_) => _loadHistory());
  }

  @override
  void dispose() {
    _messageController.dispose();
    _categoryController.dispose();
    _quantityController.dispose();
    _addressController.dispose();
    MessageService.instance.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Column(
        children: [
          if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      final isMine = m['senderId']?.toString() == _currentUserId;
                      final content = (m['content'] ?? '').toString();
                      final order = (m['orderDetails'] as Map?)?.cast<String, dynamic>();
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(content),
                              if (order != null && order.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text('Order: ${order['category'] ?? ''} | Qty: ${order['quantity'] ?? ''}'),
                                if ((order['deliveryAddress'] ?? '').toString().isNotEmpty)
                                  Text('Address: ${order['deliveryAddress']}'),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Type a message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _categoryController,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _quantityController,
                        decoration: const InputDecoration(labelText: 'Quantity', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Delivery Address (optional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


