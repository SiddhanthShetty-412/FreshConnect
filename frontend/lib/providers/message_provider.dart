import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message.dart';
import '../services/message_service.dart';

class MessageProvider extends ChangeNotifier {
  final List<MessageModel> _currentConversation = <MessageModel>[];
  String? _currentUserId;
  String? _otherUserId;
  bool _listening = false;

  List<MessageModel> get currentConversation => List.unmodifiable(_currentConversation);
  String? get otherUserId => _otherUserId;

  Future<void> _ensureSocketConnected() async {
    if (_currentUserId == null) {
      final prefs = await SharedPreferences.getInstance();
      _currentUserId = prefs.getString('userId');
    }
    await MessageService.instance.connect(_currentUserId ?? '');
  }

  Future<void> fetchConversation(String userId) async {
    _otherUserId = userId;
    await _ensureSocketConnected();
    final res = await MessageService.instance.getConversation(_currentUserId ?? '', userId);
    final list = (res['messages'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
    _currentConversation
      ..clear()
      ..addAll(list.map((m) => MessageModel.fromJson(m)));
    notifyListeners();
  }

  Future<void> sendMessage(String content, {OrderDetails? orderDetails}) async {
    if (_otherUserId == null || (_otherUserId?.isEmpty ?? true)) return;
    final res = await MessageService.instance.sendMessage(
      _otherUserId!,
      content,
      orderDetails: orderDetails == null ? null : orderDetails.toJson(),
    );
    final sent = (res['message'] as Map?)?.cast<String, dynamic>();
    if (sent != null) {
      final msg = MessageModel.fromJson(sent);
      _currentConversation.add(msg);
      notifyListeners();
    }
    // Emit via socket for realtime to receiver
    final socketPayload = <String, dynamic>{
      'receiverId': _otherUserId,
      'senderId': _currentUserId,
      'content': content,
      if (orderDetails != null) 'orderDetails': orderDetails.toJson(),
    };
    MessageService.instance.sendMessageSocket(socketPayload);
  }

  Future<void> listenForNewMessages() async {
    if (_listening) return;
    _listening = true;
    await _ensureSocketConnected();
    MessageService.instance.onNewMessage((msg) {
      try {
        final map = msg;
        final senderId = (map['senderId'] ?? '').toString();
        final receiverId = (map['receiverId'] ?? '').toString();
        if (_otherUserId == null) return;
        final isForThisChat = senderId == _otherUserId || receiverId == _otherUserId;
        if (!isForThisChat) return;
        _currentConversation.add(MessageModel.fromJson(map));
        notifyListeners();
      } catch (_) {
        // ignore malformed socket payloads
      }
    });
  }

  @override
  void dispose() {
    _listening = false;
    super.dispose();
  }
}


