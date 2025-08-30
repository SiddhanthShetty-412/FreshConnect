import 'user.dart';
import 'message.dart';

class ConversationModel {
  final UserModel user; // the other participant
  final MessageModel lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.user,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      lastMessage: MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>),
      unreadCount: (json['unreadCount'] is num) ? (json['unreadCount'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'user': user.toJson(),
      'lastMessage': lastMessage.toJson(),
      'unreadCount': unreadCount,
    };
  }
}


