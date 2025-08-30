import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  static String get _baseUrl => ApiConfig.baseUrl;
  static const String _authHeader = 'Authorization';
  static const String _bearer = 'Bearer ';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _setAuth(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setString('userId', user['_id']?.toString() ?? '');
    await prefs.setString('userRole', user['role']?.toString() ?? '');
  }

  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userId');
    await prefs.remove('userRole');
  }

  /// ✅ FIX: Ensure all endpoints automatically get `/api` prefix
  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized = path.startsWith('/api') ? path : '/api$path';
    return Uri.parse('$_baseUrl$normalized').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  Future<Map<String, String>> _headers({bool withAuth = false}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await _getToken();
      if (token != null && token.isNotEmpty) {
        headers[_authHeader] = _bearer + token;
      }
    }
    return headers;
  }

  // -------------------- Generic Request Helpers --------------------
  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool withAuth = true,
  }) async {
    final uri = _uri(path, query);
    final headers = await _headers(withAuth: withAuth);

    http.Response res;
    switch (method.toUpperCase()) {
      case 'GET':
        res = await http.get(uri, headers: headers);
        break;
      case 'POST':
        res = await http.post(uri, headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      case 'PUT':
        res = await http.put(uri, headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      default:
        throw Exception('Unsupported method: $method');
    }

    if (res.statusCode == 401 || res.statusCode == 403) {
      await clearAuth();
      throw Exception('Unauthorized');
    }

    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;
    throw _error(res);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool withAuth = true}) {
    return _request('GET', path, query: query, withAuth: withAuth);
  }

  Future<dynamic> post(String path, {Object? body, Map<String, dynamic>? query, bool withAuth = true}) {
    return _request('POST', path, query: query, body: body, withAuth: withAuth);
  }

  Future<dynamic> put(String path, {Object? body, Map<String, dynamic>? query, bool withAuth = true}) {
    return _request('PUT', path, query: query, body: body, withAuth: withAuth);
  }

  Future<dynamic> delete(String path, {Object? body, Map<String, dynamic>? query, bool withAuth = true}) {
    return _request('DELETE', path, query: query, body: body, withAuth: withAuth);
  }

  dynamic _decode(http.Response res) {
    try {
      return jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      return null;
    }
  }

  Exception _error(http.Response res, {String? fallback}) {
    final decoded = _decode(res);
    final message = (decoded is Map && decoded['message'] is String)
        ? decoded['message'] as String
        : (fallback ?? 'Unexpected error');
    return Exception(message);
  }

  // -------------------- Health --------------------
  Future<Map<String, dynamic>> getHealth() async {
    final res = await http.get(_uri('/health'), headers: await _headers());
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw _error(res, fallback: 'Failed to fetch health');
  }

  // -------------------- Auth --------------------
  Future<Map<String, dynamic>> login(String phone, String password, {bool persist = true}) async {
    final res = await http.post(
      _uri('/auth/login'),
      headers: await _headers(),
      body: jsonEncode({'phone': phone, 'password': password}),
    );
    if (res.statusCode == 401 || res.statusCode == 403) {
      await clearAuth();
      throw Exception('Unauthorized');
    }
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic>) {
      final token = (data['token'] ?? data['data']?['token'])?.toString();
      if (token != null && token.isNotEmpty) {
        if (persist) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
        }
        return data;
      }
    }
    throw _error(res, fallback: 'Failed to login');
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final res = await http.post(
      _uri('/auth/register'),
      headers: await _headers(),
      body: jsonEncode(userData),
    );
    final data = _decode(res);
    if ((res.statusCode == 200 || res.statusCode == 201) && data is Map<String, dynamic>) return data;
    throw _error(res, fallback: 'Failed to register');
  }

  Future<Map<String, dynamic>> getProfile() async {
    final data = await get('/auth/profile');
    if (data is Map<String, dynamic>) return data;
    throw Exception('Invalid profile response');
  }

  Future<void> logout() async {
    await clearAuth();
  }

  Future<Map<String, dynamic>> sendOtp({required String phone}) async {
    final res = await http.post(
      _uri('/auth/send-otp'),
      headers: await _headers(),
      body: jsonEncode({'phone': phone}),
    );
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic>) return data;
    throw _error(res, fallback: 'Failed to send OTP');
  }

  Future<Map<String, dynamic>> verifyOtp({required String phone, required String otp, bool persist = true}) async {
    final res = await http.post(
      _uri('/auth/verify-otp'),
      headers: await _headers(),
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic> && data['success'] == true) {
      if (persist) await _setAuth(data['token'] as String, (data['user'] as Map).cast<String, dynamic>());
      return data;
    }
    throw _error(res, fallback: 'Failed to verify OTP');
  }

  Future<Map<String, dynamic>> signup({
    required String name,
    required String phone,
    required String role,
    required String location,
    required String otp,
    List<String>? categories,
    String? description,
    bool persist = true,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'role': role,
      'location': location,
      'otp': otp,
      if (categories != null) 'categories': categories,
      if (description != null) 'description': description,
    };
    final res = await http.post(
      _uri('/auth/signup'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = _decode(res);
    if ((res.statusCode == 201 || res.statusCode == 200) && data is Map<String, dynamic> && data['success'] == true) {
      if (persist) await _setAuth(data['token'] as String, (data['user'] as Map).cast<String, dynamic>());
      return data;
    }
    throw _error(res, fallback: 'Failed to signup');
  }

  // -------------------- Suppliers --------------------
  Future<Map<String, dynamic>> getSuppliers({String? location, String? category}) async {
    final res = await http.get(
      _uri('/suppliers', {
        if (location != null && location.isNotEmpty) 'location': location,
        if (category != null && category.isNotEmpty) 'category': category,
      }),
      headers: await _headers(withAuth: true),
    );
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic> && data['success'] == true) return data;
    throw _error(res, fallback: 'Failed to fetch suppliers');
  }

  Future<Map<String, dynamic>> getSupplierById(String id) async {
    final res = await http.get(_uri('/suppliers/$id'), headers: await _headers(withAuth: true));
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic> && data['success'] == true) return data;
    throw _error(res, fallback: 'Failed to fetch supplier');
  }

  Future<Map<String, dynamic>> updateSupplierProfile({
    List<String>? categories,
    String? description,
    String? deliveryTime,
  }) async {
    final body = <String, dynamic>{
      if (categories != null) 'categories': categories,
      if (description != null) 'description': description,
      if (deliveryTime != null) 'deliveryTime': deliveryTime,
    };
    final res = await http.put(
      _uri('/suppliers/profile'),
      headers: await _headers(withAuth: true),
      body: jsonEncode(body),
    );
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic> && data['success'] == true) return data;
    throw _error(res, fallback: 'Failed to update profile');
  }

  // -------------------- Messages --------------------
  Future<Map<String, dynamic>> getConversations() async {
    final res = await http.get(_uri('/messages/conversations'), headers: await _headers(withAuth: true));
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic> && data['success'] == true) return data;
    throw _error(res, fallback: 'Failed to fetch conversations');
  }

  Future<Map<String, dynamic>> getConversation({required String userId1, required String userId2}) async {
    final res = await http.get(_uri('/messages/$userId1/$userId2'), headers: await _headers(withAuth: true));
    final data = _decode(res);
    if (res.statusCode == 200 && data is Map<String, dynamic> && data['success'] == true) return data;
    throw _error(res, fallback: 'Failed to fetch messages');
  }

  Future<Map<String, dynamic>> sendMessage({
    required String receiverId,
    required String content,
    Map<String, dynamic>? orderDetails,
  }) async {
    final body = <String, dynamic>{
      'receiverId': receiverId,
      'content': content,
      if (orderDetails != null) 'orderDetails': orderDetails,
    };
    final res = await http.post(
      _uri('/messages'),
      headers: await _headers(withAuth: true),
      body: jsonEncode(body),
    );
    final data = _decode(res);
    if (res.statusCode == 201 && data is Map<String, dynamic> && data['success'] == true) return data;
    throw _error(res, fallback: 'Failed to send message');
  }
}
