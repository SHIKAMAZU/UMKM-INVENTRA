import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);
const _mint = Color(0xFFDDF4E8);

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.session});

  final Session session;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _loading = true;
  String? _error;
  int _products = 0;
  int _stock = 0;
  int _low = 0;
  List<Map<String, dynamic>> _lowProducts = [];

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
      final api = ApiClient(widget.session);
      final productJson = await api.get('/api/products?limit=100');
      final products = (productJson['data'] as List)
          .cast<Map<String, dynamic>>();

      final lowProducts = products
          .where(
            (item) =>
                (item['stock'] as num).toInt() <=
                (item['min_stock'] as num).toInt(),
          )
          .toList()
        ..sort(
          (a, b) => (a['stock'] as num)
              .toInt()
              .compareTo((b['stock'] as num).toInt()),
        );

      if (!mounted) return;
      setState(() {
        _products =
            (productJson['meta']?['total'] as num?)?.toInt() ??
            products.length;
        _stock = products.fold(
          0,
          (sum, item) => sum + (item['stock'] as num).toInt(),
        );
        _low = lowProducts.length;
        _lowProducts = lowProducts;
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
        _error = 'Gagal memuat laporan';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Laporan'),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  _statsGrid(),
                  const SizedBox(height: 20),
                  _stockHealthCard(),
                  const SizedBox(height: 20),
                  _lowStockCard(),
                ],
              ),
            ),
    );
  }

  Widget _statsGrid() {
    final avgStock = _products == 0 ? 0 : (_stock / _products).round();

    return Column(
      children: [
        Row(
          children: [
            _statCard(
              Icons.inventory_2_outlined,
              _green,
              '$_products',
              'Total Produk',
            ),
            const SizedBox(width: 12),
            _statCard(
              Icons.layers_outlined,
              const Color(0xFF1D6FD6),
              '$_stock',
              'Total Stok',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(
              Icons.warning_amber_rounded,
              Colors.orange,
              '$_low',
              'Stok Menipis',
            ),
            const SizedBox(width: 12),
            _statCard(
              Icons.straighten,
              const Color(0xFF7C3AED),
              '$avgStock',
              'Rata-rata Stok',
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, Color color, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stockHealthCard() {
    final safe = (_products - _low).clamp(0, _products);
    final ratio = _products == 0 ? 0.0 : safe / _products;
    final healthy = _products == 0 || _low == 0;
    final accent = healthy ? _green : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _mint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  color: _dark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kesehatan Stok',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      'Persentase produk dengan stok aman',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(ratio * 100).round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: _bg,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _products == 0
                ? 'Belum ada produk untuk dinilai.'
                : healthy
                ? 'Semua ($safe) produk stoknya masih aman.'
                : '$safe dari $_products produk aman, $_low perlu segera restok.',
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lowStockCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFB91C1C),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produk Stok Menipis',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Segera lakukan restok',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _lowProducts.isEmpty
                        ? _mint
                        : const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_lowProducts.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _lowProducts.isEmpty
                          ? _green
                          : const Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_lowProducts.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, color: _green, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Semua stok barang masih aman.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final product in _lowProducts) _lowStockItem(product),
        ],
      ),
    );
  }

  Widget _lowStockItem(Map<String, dynamic> product) {
    final stock = (product['stock'] as num).toInt();
    final minStock = (product['min_stock'] as num).toInt();
    final ratio = minStock == 0 ? 0.0 : (stock / minStock).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: _dark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${product['name']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    Text(
                      '${product['sku']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$stock',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFFB91C1C),
                ),
              ),
              Text(
                ' / $minStock',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFEF4444),
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
          Text(_error ?? 'Gagal memuat laporan'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
