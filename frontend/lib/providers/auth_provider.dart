import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  String? _token;

  UserModel? get currentUser => _currentUser;
  String? get token => _token;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  Future<void> loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null && _token!.isNotEmpty) {
      try {
        final data = await AuthService.instance.getCurrentUser();
        // API may return { success, user: {...} } or just user
        final userJson = (data['user'] is Map)
            ? (data['user'] as Map).cast<String, dynamic>()
            : (data as Map).cast<String, dynamic>();
        _currentUser = UserModel.fromJson(userJson);
      } catch (_) {
        // If token invalid, clear it
        await logout();
      }
    }
    notifyListeners();
  }

  Future<void> login({required String token}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    _token = token;
    try {
      final data = await AuthService.instance.getCurrentUser();
      final userJson = (data['user'] is Map)
          ? (data['user'] as Map).cast<String, dynamic>()
          : (data as Map).cast<String, dynamic>();
      _currentUser = UserModel.fromJson(userJson);
    } catch (_) {
      await logout();
      rethrow;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userRole');
    _token = null;
    _currentUser = null;
    notifyListeners();
  }
}


