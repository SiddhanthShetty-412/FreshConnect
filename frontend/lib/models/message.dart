class OrderDetails {
  final String? category; // 'Vegetables' | 'Fruits' | 'Grains' | 'Meat' | 'Dairy Products'
  final String? quantity;
  final String? deliveryAddress;

  const OrderDetails({this.category, this.quantity, this.deliveryAddress});

  factory OrderDetails.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const OrderDetails();
    return OrderDetails(
      category: json['category']?.toString(),
      quantity: json['quantity']?.toString(),
      deliveryAddress: json['deliveryAddress']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (deliveryAddress != null) 'deliveryAddress': deliveryAddress,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final OrderDetails orderDetails;
  final DateTime timestamp;
  final bool isRead;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.orderDetails,
    required this.timestamp,
    required this.isRead,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      senderId: (json['senderId'] ?? '').toString(),
      receiverId: (json['receiverId'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      orderDetails: OrderDetails.fromJson(json['orderDetails'] as Map<String, dynamic>?),
      timestamp: DateTime.tryParse((json['timestamp'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()).toString()) ?? DateTime.now(),
      isRead: (json['isRead'] ?? false) == true,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '_id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'orderDetails': orderDetails.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }
}


