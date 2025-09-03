import 'package:frontend/services/api_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // Send OTP to phone
  Future<Map<String, dynamic>> sendOtp(String phone) {
    return ApiService.instance.sendOtp(phone: phone);
  }

  // Verify OTP → may return token+user (existing user) or newUser flag
  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) {
    return ApiService.instance.verifyOtp(phone: phone, otp: otp, persist: true);
  }

  // Complete profile (signup) using authenticated request; persists JWT
  Future<Map<String, dynamic>> completeProfile({
    required String name,
    required String role,
    required String location,
  }) async {
    return ApiService.instance.completeProfile(name: name, role: role, location: location);
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


