import 'package:flutter/material.dart';
import 'package:frontend/services/supplier_service.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _suppliers = const [];

  @override
  void dispose() {
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupplierService.instance.getSuppliers(
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      );
      final list = (res['suppliers'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      setState(() => _suppliers = list);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loading ? null : _loadSuppliers,
                  child: _loading
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Filter'),
                ),
              ],
            ),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
          Expanded(
            child: _loading && _suppliers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _suppliers.length,
                    itemBuilder: (context, index) {
                      final s = _suppliers[index];
                      final id = (s['_id'] ?? '').toString();
                      final name = (s['name'] ?? '').toString();
                      final location = (s['location'] ?? '').toString();
                      final rating = (s['rating'] ?? 0).toString();
                      final categories = ((s['categories'] as List?)?.map((e) => e.toString()).toList() ?? const <String>[]).join(', ');
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(name.isEmpty ? 'Unnamed Supplier' : name),
                          subtitle: Text('Location: $location\nCategories: $categories\nRating: $rating'),
                          isThreeLine: true,
                          onTap: () => Navigator.of(context).pushNamed('/suppliers/detail', arguments: {'id': id}),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}


