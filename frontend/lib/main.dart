import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/otp_verification_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/suppliers/supplier_list_screen.dart';
import 'screens/suppliers/supplier_detail_screen.dart';
import 'screens/chat/conversation_list_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'theme/app_theme.dart';
import 'screens/profile/profile_screen.dart';

import 'providers/auth_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/message_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUserFromStorage()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
      ],
      child: MaterialApp(
        title: 'FreshConnect',
        theme: AppTheme.light,
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/otp': (context) => const OtpVerificationScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/suppliers': (context) => const SupplierListScreen(),
          '/chat': (context) => const ConversationListScreen(),
          '/profile': (context) => const ProfileScreen(),
        },
        onGenerateRoute: (settings) {
          final name = settings.name ?? '';
          if (name.startsWith('/supplier/')) {
            final id = name.replaceFirst('/supplier/', '');
            return MaterialPageRoute(
              builder: (_) => const SupplierDetailScreen(),
              settings: RouteSettings(arguments: {'id': id}),
            );
          }
          if (name.startsWith('/chat/')) {
            final id = name.replaceFirst('/chat/', '');
            return MaterialPageRoute(
              builder: (_) => const ChatScreen(),
              settings: RouteSettings(arguments: {'receiverId': id}),
            );
          }
          // Back-compat for earlier internal routes used in screens
          if (name == '/suppliers/detail') {
            return MaterialPageRoute(builder: (_) => const SupplierDetailScreen(), settings: settings);
          }
          if (name == '/messages/chat') {
            return MaterialPageRoute(builder: (_) => const ChatScreen(), settings: settings);
          }
          return null;
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (!mounted) return;
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

// DashboardScreen moved to screens/dashboard/dashboard_screen.dart
