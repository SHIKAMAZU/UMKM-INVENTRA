import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key, required this.session});

  final Session session;

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sales = [];

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
      final json = await ApiClient(widget.session).get('/api/sales?limit=50');
      if (!mounted) return;
      setState(() {
        _sales = (json['data'] as List).cast<Map<String, dynamic>>();
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
        _error = 'Gagal memuat riwayat penjualan';
        _loading = false;
      });
    }
  }

  String _date(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '-';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }

  Future<void> _delete(int id) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat'),
        content: const Text(
          'Hapus transaksi ini? Stok barang akan dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (sure != true) return;

    try {
      await ApiClient(widget.session).delete('/api/sales/$id');
      if (!mounted) return;
      _showMessage('TRX-$id dihapus dan stok dikembalikan');
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Gagal menghapus riwayat');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Riwayat Penjualan'),
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
              child: _sales.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.receipt_long_outlined, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada transaksi penjualan',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _sales.length,
                      itemBuilder: (_, index) => _item(_sales[index]),
                    ),
            ),
    );
  }

  Widget _item(Map<String, dynamic> sale) {
    final id = (sale['id'] as num).toInt();
    final total = (sale['total'] as num).toDouble();
    final itemCount = (sale['item_count'] as num).toInt();
    final totalQuantity = (sale['total_quantity'] as num).toInt();

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
            child: const Icon(Icons.receipt_long, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRX-$id',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$itemCount jenis • $totalQuantity barang',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  '${sale['user_name']} • ${_date(sale['created_at'])}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          Text(
            'Rp ${total.toStringAsFixed(0)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _dark,
            ),
          ),
          if (widget.session.user?.role == 'admin')
            IconButton(
              onPressed: () => _delete(id),
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.red,
              ),
              tooltip: 'Hapus',
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
          Text(_error ?? 'Gagal memuat riwayat penjualan'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
