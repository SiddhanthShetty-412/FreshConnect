import 'dart:async';

import 'package:frontend/services/api_service.dart';
import 'package:frontend/services/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class MessageService {
  MessageService._();
  static final MessageService instance = MessageService._();

  io.Socket? _socket;
  bool _isConnecting = false;

  // -------------------- REST --------------------
  Future<Map<String, dynamic>> getConversation(String userId1, String userId2) {
    return ApiService.instance.getConversation(userId1: userId1, userId2: userId2);
  }

  Future<Map<String, dynamic>> sendMessage(String receiverId, String content, {Map<String, dynamic>? orderDetails}) {
    return ApiService.instance.sendMessage(receiverId: receiverId, content: content, orderDetails: orderDetails);
  }

  Future<Map<String, dynamic>> getConversations() {
    return ApiService.instance.getConversations();
  }

  // -------------------- Socket.IO --------------------
  Future<void> connect(String userId) async {
    if (_socket != null && _socket!.connected) return;
    if (_isConnecting) return; // Prevent multiple connection attempts
    
    _isConnecting = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final opts = <String, dynamic>{
        'transports': ['websocket', 'polling'], // Fallback to polling if websocket fails
        'autoConnect': false,
        'timeout': 20000, // 20 second timeout
        'extraHeaders': {
          'Authorization': token != null && token.isNotEmpty ? 'Bearer $token' : '',
        },
      };

      // Use the current base URL for Socket.IO connection
      final socketUrl = ApiConfig.currentBaseUrl;
      print('🔌 Connecting to Socket.IO at: $socketUrl');
      
      _socket = io.io(socketUrl, opts);
      
      _socket!.onConnect((_) {
        print('✅ Socket.IO connected successfully');
        _socket!.emit('join', {'userId': userId});
        _isConnecting = false;
      });
      
      _socket!.onConnectError((error) {
        print('❌ Socket.IO connection error: $error');
        _isConnecting = false;
      });
      
      _socket!.onDisconnect((reason) {
        print('🔌 Socket.IO disconnected: $reason');
        _isConnecting = false;
      });
      
      _socket!.connect();
    } catch (e) {
      print('❌ Error setting up Socket.IO connection: $e');
      _isConnecting = false;
      rethrow;
    }
  }

  void onNewMessage(void Function(Map<String, dynamic> message) callback) {
    _socket?.on('newMessage', (data) {
      if (data is Map) {
        callback(data.cast<String, dynamic>());
      } else if (data is String) {
        print('⚠️ Unexpected message format: String');
      }
    });
  }

  void sendMessageSocket(Map<String, dynamic> message) {
    if (_socket?.connected == true) {
      _socket!.emit('sendMessage', message);
    } else {
      print('⚠️ Socket not connected, message not sent via Socket.IO');
    }
  }

  Future<void> disconnect() async {
    _isConnecting = false;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }
  
  bool get isConnected => _socket?.connected ?? false;
}


