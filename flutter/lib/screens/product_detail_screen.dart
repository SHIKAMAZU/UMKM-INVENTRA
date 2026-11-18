import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/session.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

typedef ProductAction = Future<bool> Function(Map<String, dynamic> product);

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.session,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Session session;
  final Map<String, dynamic> product;
  final ProductAction onEdit;
  final ProductAction onDelete;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Map<String, dynamic> _product;

  bool get _isAdmin => widget.session.user?.role == 'admin';

  int get _stock => (_product['stock'] as num?)?.toInt() ?? 0;
  int get _minStock => (_product['min_stock'] as num?)?.toInt() ?? 0;
  bool get _isLowStock => _stock <= _minStock;

  @override
  void initState() {
    super.initState();
    _product = Map<String, dynamic>.from(widget.product);
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final json = await ApiClient(
        widget.session,
      ).get('/api/products/${_product['id']}');
      if (!mounted) return;
      setState(() {
        _product = json['data'] as Map<String, dynamic>;
      });
    } catch (_) {
      return;
    }
  }

  Future<void> _edit() async {
    final saved = await widget.onEdit(_product);
    if (saved && mounted) {
      await _refresh();
    }
  }

  Future<void> _delete() async {
    final deleted = await widget.onDelete(_product);
    if (deleted && mounted) {
      Navigator.pop(context, true);
    }
  }

  String? get _imageUrl {
    final url = '${_product['image_url'] ?? ''}'.trim();
    if (url.isEmpty) return null;
    return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
  }

  String _rupiah(num value) {
    final digits = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return 'Rp $buffer';
  }

  @override
  Widget build(BuildContext context) {
    final name = '${_product['name'] ?? '-'}';
    final sku = '${_product['sku'] ?? '-'}';
    final category = '${_product['category_name'] ?? '-'}';
    final price = (_product['price'] as num?) ?? 0;
    final description = '${_product['description'] ?? ''}'.trim();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Detail Produk'),
        backgroundColor: _bg,
        foregroundColor: _dark,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _imageCard(),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SKU $sku',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      _stockBadge(),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(Icons.category_outlined, category),
                      if (_isLowStock)
                        _chip(
                          Icons.warning_amber_rounded,
                          'Stok menipis',
                          danger: true,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Harga jual',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _rupiah(price),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _dark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          'Stok saat ini',
                          '$_stock',
                          Icons.inventory_2_outlined,
                          danger: _isLowStock,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          'Stok minimal',
                          '$_minStock',
                          Icons.warning_amber_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isEmpty
                        ? 'Belum ada deskripsi untuk produk ini.'
                        : description,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
            ),
            if (_isAdmin) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFB91C1C),
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Produk'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _imageCard() {
    final url = _imageUrl;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 240,
        width: double.infinity,
        color: Colors.white,
        child: url == null
            ? const Center(
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 72,
                  color: _green,
                ),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    size: 56,
                    color: _green,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _stockBadge() {
    final color = _isLowStock ? const Color(0xFFB91C1C) : _green;
    final background = _isLowStock
        ? const Color(0xFFFEE2E2)
        : const Color(0xFFDDF4E8);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Stok $_stock',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, {bool danger = false}) {
    final color = danger ? const Color(0xFFB91C1C) : _dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String label,
    String value,
    IconData icon, {
    bool danger = false,
  }) {
    final color = danger ? const Color(0xFFB91C1C) : _green;
    final background = danger ? const Color(0xFFFEE2E2) : _bg;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: danger ? color : const Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
