import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

const _dark = Color(0xFF0B5D4E);
const _bg = Color(0xFFE6F7EF);

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, required this.session});

  final Session session;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final json = await ApiClient(
        widget.session,
      ).get('/api/products?low_stock=true&limit=20');
      if (!mounted) return;
      setState(() {
        _items = (json['data'] as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Gagal memuat notifikasi';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Notifikasi'),
        backgroundColor: _bg,
        foregroundColor: _dark,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.notifications_off, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Tidak ada notifikasi',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDF4E8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Ada ${_items.length} barang yang stoknya '
                                  'hampir habis.',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final item in _items) _item(item),
                      ],
                    ),
            ),
    );
  }

  Widget _item(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: _dark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${product['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Stok tersisa ${product['stock']} '
                  '(minimal ${product['min_stock']})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Segera Restok',
              style: TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Color(0xFF6B7280)),
          const SizedBox(height: 12),
          Text(_error ?? 'Gagal memuat notifikasi'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
