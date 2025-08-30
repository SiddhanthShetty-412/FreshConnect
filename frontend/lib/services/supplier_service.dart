import 'package:frontend/services/api_service.dart';

class SupplierService {
  SupplierService._();
  static final SupplierService instance = SupplierService._();

  Future<Map<String, dynamic>> getSuppliers({String? location, String? category}) {
    return ApiService.instance.getSuppliers(location: location, category: category);
  }

  Future<Map<String, dynamic>> getSupplierById(String id) {
    return ApiService.instance.getSupplierById(id);
  }

  Future<Map<String, dynamic>> updateProfile({
    List<String>? categories,
    String? description,
    String? deliveryTime,
  }) {
    return ApiService.instance.updateSupplierProfile(
      categories: categories,
      description: description,
      deliveryTime: deliveryTime,
    );
  }
}


