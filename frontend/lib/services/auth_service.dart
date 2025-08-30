import 'package:frontend/services/api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Send OTP to phone
  Future<Map<String, dynamic>> sendOtp(String phone) {
    return ApiService.instance.sendOtp(phone: phone);
  }

  // Verify OTP → persists JWT in storage (handled by ApiService.verifyOtp when persist=true)
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) {
    return ApiService.instance.verifyOtp(phone: phone, otp: otp, persist: true);
  }

  // Complete profile (signup) → returns JWT + user, persists when persist=true
  Future<Map<String, dynamic>> signup(Map<String, dynamic> userData) async {
    final name = (userData['name'] ?? '').toString();
    final phone = (userData['phone'] ?? '').toString();
    final role = (userData['role'] ?? '').toString();
    final location = (userData['location'] ?? '').toString();
    final otp = (userData['otp'] ?? '').toString();
    final categories = (userData['categories'] is List)
        ? (userData['categories'] as List).map((e) => e.toString()).toList()
        : null;
    final description = userData['description']?.toString();

    return ApiService.instance.signup(
      name: name,
      phone: phone,
      role: role,
      location: location,
      otp: otp,
      categories: categories,
      description: description,
      persist: true,
    );
  }

  // Fetch current user using stored JWT token
  Future<Map<String, dynamic>> getCurrentUser() {
    return ApiService.instance.getProfile();
  }

  // Logout → removes token
  Future<void> logout() {
    return ApiService.instance.logout();
  }
}


