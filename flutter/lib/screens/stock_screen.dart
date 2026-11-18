import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class StockScreen extends StatefulWidget {
  const StockScreen({super.key, required this.session});

  final Session session;

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];

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
      ).get('/api/products?limit=100');
      if (!mounted) return;
      setState(() {
        _products = (json['data'] as List).cast<Map<String, dynamic>>();
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
        _error = 'Gagal memuat data stok';
        _loading = false;
      });
    }
  }

  Future<void> _updateStock(Map<String, dynamic> product) async {
    final qty = TextEditingController();
    String type = 'in';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Stok ${product['name']} (sekarang ${product['stock']})',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: InputDecoration(
                  labelText: 'Jenis',
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'in', child: Text('Stok Masuk')),
                  DropdownMenuItem(value: 'out', child: Text('Stok Keluar')),
                  DropdownMenuItem(value: 'adjust', child: Text('Sesuaikan')),
                ],
                onChanged: (value) => setSheet(() => type = value ?? 'in'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qty,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  filled: true,
                  fillColor: _bg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _green),
                onPressed: () async {
                  final quantity = int.tryParse(qty.text) ?? 0;
                  if (quantity <= 0) {
                    _showMessage('Jumlah harus lebih dari 0');
                    return;
                  }
                  try {
                    await ApiClient(widget.session).post(
                      '/api/products/${product['id']}/stock',
                      {'type': type, 'quantity': quantity},
                    );
                    if (context.mounted) Navigator.pop(context, true);
                  } on ApiException catch (error) {
                    _showMessage(error.message);
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );

    qty.dispose();
    if (saved == true) {
      _showMessage('Stok berhasil diperbarui');
      await _load();
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
        title: const Text('Kelola Stok'),
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
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _products.length,
                itemBuilder: (_, index) => _item(_products[index]),
              ),
            ),
    );
  }

  Widget _item(Map<String, dynamic> product) {
    final stock = (product['stock'] as num).toInt();
    final minStock = (product['min_stock'] as num).toInt();
    final low = stock <= minStock;

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
            child: const Icon(Icons.layers, color: _green),
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
                  '${product['sku']} • min $minStock',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: low ? const Color(0xFFFEE2E2) : const Color(0xFFDDF4E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$stock',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: low ? const Color(0xFFB91C1C) : _green,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _updateStock(product),
            icon: const Icon(Icons.edit_outlined, color: _dark),
            tooltip: 'Ubah stok',
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
          Text(_error ?? 'Gagal memuat data stok'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
