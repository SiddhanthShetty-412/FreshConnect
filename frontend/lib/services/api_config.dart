import 'dart:io';
import 'package:flutter/foundation.dart';

/// Configuration class for API endpoints with platform-specific base URLs
class ApiConfig {
  /// Environment configuration
  static const String _devUrl = "http://localhost:5000";
  static const String _prodUrl = "https://server-b5n53wuax-siddhanth-shettys-projects.vercel.app";
  
  /// Base URL for API calls that automatically adapts to the current platform
  /// 
  /// Platform-specific URLs:
  /// - Android Emulator: http://10.0.2.2:5000 (10.0.2.2 is the special IP that maps to host machine's localhost)
  /// - iOS Simulator: http://localhost:5000 (iOS simulator can access host machine's localhost directly)
  /// - Web (Chrome): http://localhost:5000 (Web apps run on the same machine as the backend)
  /// - Physical Devices: http://192.168.1.100:5000 (Replace with your actual local IP address)
  static String get baseUrl {
    // Check if we're in production mode (you can set this via environment variable)
    const bool isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
    
    if (isProduction) {
      return _prodUrl;
    }
    
    if (kIsWeb) {
      // Web platform - use localhost since web app runs on same machine as backend
      return _devUrl;
    } else if (Platform.isAndroid) {
      // Android platform - check if running on emulator or physical device
      // For emulator, use 10.0.2.2 which maps to host machine's localhost
      // For physical device, use your local network IP (replace with actual IP)
      return "http://10.0.2.2:5000";
    } else if (Platform.isIOS) {
      // iOS platform - simulator can access localhost directly
      // For physical device, you'll need to replace with your local network IP
      return _devUrl;
    } else {
      // Fallback for other platforms (Windows, macOS, Linux)
      return _devUrl;
    }
  }

  /// Alternative method to get base URL for physical devices
  /// Use this when testing on physical devices by replacing with your actual local IP
  static String get baseUrlForPhysicalDevice {
    return "http://192.168.1.100:5000"; // Replace with your actual local IP address
  }

  /// Helper method to check if running on emulator/simulator
  static bool get isEmulator {
    if (kIsWeb) return false;
    if (Platform.isAndroid) {
      // Android emulator check - you might want to add more sophisticated detection
      return true; // Assume emulator for now, you can enhance this detection
    } else if (Platform.isIOS) {
      // iOS simulator check - you might want to add more sophisticated detection
      return true; // Assume simulator for now, you can enhance this detection
    }
    return false;
  }
  
  /// Get the appropriate base URL for the current environment
  static String get currentBaseUrl {
    // For physical devices, you might want to use a different URL
    if (!kIsWeb && !isEmulator) {
      return baseUrlForPhysicalDevice;
    }
    return baseUrl;
  }
}
