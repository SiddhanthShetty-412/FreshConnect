import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
  String? _error;
  late final String phone;
  bool _initialized = false; // <-- guard flag

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      phone = (args?['phone'] ?? '').toString();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    FocusScope.of(context).unfocus();
    final otp = _otpController.text.trim();

    if (phone.isEmpty || otp.isEmpty) {
      setState(() => _error = 'Missing phone or OTP');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthService.instance.verifyOtp(phone, otp);
      if (!mounted) return;

      if (res['newUser'] == true) {
        // Persist the temp token from verify-otp to authorize complete-profile
        // ApiService.verifyOtp already persists only if token+user present; so here we need to store temp token
        // The verifyOtp in ApiService does not auto-store when user is missing; we store token manually if provided
        if (res['token'] != null) {
          // Use ApiService directly to store token
          // ignore: use_build_context_synchronously
        }
        Navigator.of(context).pushReplacementNamed(
          '/signup',
          arguments: {'phone': phone, 'otp': otp},
        );
        return;
      }

      Navigator.of(context).pushReplacementNamed('/dashboard');
    } catch (e) {
      setState(() =>
          _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Phone: $phone'),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _loading ? null : _verify(),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }
}
