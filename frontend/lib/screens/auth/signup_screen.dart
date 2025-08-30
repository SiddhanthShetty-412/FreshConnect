import 'package:flutter/material.dart';
import 'package:frontend/services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deliveryTimeController =
      TextEditingController(text: '2-4 hours');

  bool _loading = false;
  String? _error;
  late final String phone;
  late final String otp;
  bool _initialized = false; // <-- added guard flag

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      phone = (args?['phone'] ?? '').toString();
      otp = (args?['otp'] ?? '').toString();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _categoriesController.dispose();
    _descriptionController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();
    final location = _locationController.text.trim();
    final categories = _categoriesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final description = _descriptionController.text.trim();
    final deliveryTime = _deliveryTimeController.text.trim();

    if (name.isEmpty || location.isEmpty) {
      setState(() => _error = 'Name and location are required');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await AuthService.instance.signup({
        'name': name,
        'phone': phone,
        'role': 'supplier',
        'location': location,
        'otp': otp,
        'categories': categories,
        'description': description,
        'deliveryTime': deliveryTime,
      });

      if (!mounted) return;

      if (res['success'] == true) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        setState(() =>
            _error = (res['message'] ?? 'Signup failed').toString());
      }
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
      appBar: AppBar(title: const Text('Complete Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Phone: $phone'),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location (Vasai | Nalla Sopara | Virar)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoriesController,
              decoration: const InputDecoration(
                labelText: 'Categories (comma-separated)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _deliveryTimeController,
              decoration: const InputDecoration(
                labelText: 'Delivery Time',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _signup,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}
