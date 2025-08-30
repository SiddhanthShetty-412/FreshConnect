class UserModel {
  final String id;
  final String name;
  final String phone;
  final String role; // 'vendor' | 'supplier'
  final String location; // 'Vasai' | 'Nalla Sopara' | 'Virar'
  final bool isVerified;
  final List<String> categories;
  final String? description;
  final double rating;
  final int totalOrders;
  final String deliveryTime;
  final bool stockAvailability;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    required this.location,
    required this.isVerified,
    required this.categories,
    this.description,
    required this.rating,
    required this.totalOrders,
    required this.deliveryTime,
    required this.stockAvailability,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      isVerified: (json['isVerified'] ?? false) == true,
      categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[],
      description: json['description']?.toString(),
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 0.0,
      totalOrders: (json['totalOrders'] is num) ? (json['totalOrders'] as num).toInt() : 0,
      deliveryTime: (json['deliveryTime'] ?? '2-4 hours').toString(),
      stockAvailability: (json['stockAvailability'] ?? true) == true,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '_id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'location': location,
      'isVerified': isVerified,
      'categories': categories,
      if (description != null) 'description': description,
      'rating': rating,
      'totalOrders': totalOrders,
      'deliveryTime': deliveryTime,
      'stockAvailability': stockAvailability,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}


