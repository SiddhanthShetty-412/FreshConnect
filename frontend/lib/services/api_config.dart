import 'package:flutter/foundation.dart';

/// Configuration class for API endpoints
class ApiConfig {
  /// Production backend URL (Render)
  static const String _prodUrl = "https://freshconnect-2.onrender.com/api";

  /// Development backend URL (local)
  static const String _devUrl = "http://localhost:5000";

  /// Get the correct base URL depending on whether running in debug or release
  static String get baseUrl {
    if (kReleaseMode) {
      return _prodUrl;
    } else {
      return _devUrl;
    }
  }

  /// Socket URL (for real-time features like chat)
  static String get socketUrl {
    if (kReleaseMode) {
      return _prodUrl;
    } else {
      return _devUrl;
    }
  }
}
