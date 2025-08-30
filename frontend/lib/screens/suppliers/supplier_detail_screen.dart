import 'package:flutter/material.dart';
import 'package:frontend/services/supplier_service.dart';

class SupplierDetailScreen extends StatefulWidget {
  const SupplierDetailScreen({super.key});

  @override
  State<SupplierDetailScreen> createState() => _SupplierDetailScreenState();
}

class _SupplierDetailScreenState extends State<SupplierDetailScreen> {
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _supplier;
  late final String supplierId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    supplierId = (args?['id'] ?? '').toString();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await SupplierService.instance.getSupplierById(supplierId);
      setState(() => _supplier = (res['supplier'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{});
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _messageSupplier() {
    final receiverId = (_supplier?['_id'] ?? '').toString();
    if (receiverId.isEmpty) return;
    Navigator.of(context).pushNamed('/messages/chat', arguments: {'receiverId': receiverId});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _supplier == null
                  ? const Center(child: Text('No data'))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (_supplier!['name'] ?? 'Unnamed').toString(),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          Text('Location: ${(_supplier!['location'] ?? '').toString()}'),
                          const SizedBox(height: 6),
                          Text('Categories: ${(((_supplier!['categories']) as List?)?.map((e) => e.toString()).toList() ?? const <String>[])..join(', ')}'),
                          const SizedBox(height: 6),
                          Text('Rating: ${(_supplier!['rating'] ?? 0).toString()}'),
                          const SizedBox(height: 12),
                          Text((_supplier!['description'] ?? '').toString()),
                          const Spacer(),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _messageSupplier,
                              child: const Text('Message Supplier'),
                            ),
                          )
                        ],
                      ),
                    ),
    );
  }
}


