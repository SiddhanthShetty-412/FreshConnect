import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/supplier_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _categoriesController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<AuthProvider>().currentUser;
    _categoriesController.text = (user?.categories ?? const <String>[]).join(', ');
    _descriptionController.text = user?.description ?? '';
    _deliveryTimeController.text = user?.deliveryTime ?? '2-4 hours';
  }

  @override
  void dispose() {
    _categoriesController.dispose();
    _descriptionController.dispose();
    _deliveryTimeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    final categories = _categoriesController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final description = _descriptionController.text.trim();
    final deliveryTime = _deliveryTimeController.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SupplierService.instance.updateProfile(
        categories: categories.isEmpty ? null : categories,
        description: description.isEmpty ? null : description,
        deliveryTime: deliveryTime.isEmpty ? null : deliveryTime,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${user?.name ?? '-'}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('Phone: ${user?.phone ?? '-'}'),
            const SizedBox(height: 4),
            Text('Role: ${user?.role ?? '-'}'),
            const SizedBox(height: 4),
            Text('Location: ${user?.location ?? '-'}'),
            const Divider(height: 24),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _logout,
                    child: const Text('Logout'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


