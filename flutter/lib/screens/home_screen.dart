import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import 'category_screen.dart';
import 'notification_screen.dart';
import 'product_screen.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'stock_screen.dart';
import 'supplier_screen.dart';
import 'transaction_screen.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.session});

  final Session session;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  int _totalProducts = 0;
  int _todaySales = 0;
  int _lowCount = 0;
  List<Map<String, dynamic>> _lowStock = [];

  @override
  void initState() {
    super.initState();
    _load(showLoading: true);
  }

  Future<void> _load({bool showLoading = false}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final api = ApiClient(widget.session);
      final all = await api.get('/api/products?limit=1');
      final low = await api.get('/api/products?low_stock=true&limit=5');
      final today = await _countTodaySales(api);

      if (!mounted) return;
      setState(() {
        _totalProducts = _total(all);
        _lowCount = _total(low);
        _lowStock = (low['data'] as List).cast<Map<String, dynamic>>();
        _todaySales = today;
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
        _error = 'Gagal memuat data. Coba lagi.';
        _loading = false;
      });
    }
  }

  int _total(Map<String, dynamic> json) {
    final meta = json['meta'] as Map?;
    return (meta?['total'] as num?)?.toInt() ?? 0;
  }

  Future<int> _countTodaySales(ApiClient api) async {
    try {
      final json = await api.get('/api/sales?limit=100');
      final now = DateTime.now();
      return (json['data'] as List).where((item) {
        final date = DateTime.tryParse('${item['created_at']}')?.toLocal();
        return date != null &&
            date.year == now.year &&
            date.month == now.month &&
            date.day == now.day;
      }).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _tab == 1
          ? ProductScreen(session: widget.session)
          : _tab == 2
          ? TransactionScreen(session: widget.session)
          : _tab == 3
          ? ProfileScreen(session: widget.session)
          : SafeArea(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _errorView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          _header(),
                          const SizedBox(height: 24),
                          const Text(
                            'Selamat Datang!',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Kelola stok barang tokomu dengan mudah 👋',
                            style: TextStyle(color: Color(0xFF4B5563)),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              _statCard(
                                Icons.inventory_2,
                                _green,
                                _totalProducts,
                                'Total Produk',
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                Icons.warning_amber_rounded,
                                Colors.orange,
                                _lowCount,
                                'Stok Menipis',
                              ),
                              const SizedBox(width: 10),
                              _statCard(
                                Icons.receipt_long,
                                _dark,
                                _todaySales,
                                'Transaksi Hari Ini',
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Menu Utama',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 2.1,
                            children: [
                              _menuTile(
                                Icons.local_shipping,
                                'Data Supplier',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => SupplierScreen(
                                        session: widget.session,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _menuTile(
                                Icons.category,
                                'Kategori',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => CategoryScreen(
                                        session: widget.session,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              _menuTile(
                                Icons.layers,
                                'Kelola Stok',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          StockScreen(session: widget.session),
                                    ),
                                  );
                                },
                              ),
                              _menuTile(
                                Icons.bar_chart,
                                'Laporan',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ReportScreen(session: widget.session),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _lowStockCard(),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: _dark,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _tab = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Produk',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: _dark, shape: BoxShape.circle),
          child: const Icon(Icons.storefront, color: Colors.white, size: 32),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INVENTRA',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _dark,
                ),
              ),
              Text(
                'Sistem Manajemen\nStok Barang Toko',
                style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => NotificationScreen(session: widget.session),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_none,
                size: 28,
                color: _dark,
              ),
            ),
            if (_lowCount > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(IconData icon, Color color, int value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTile(IconData icon, String label, {required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _green, size: 24),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lowStockCard() {
    if (_lowCount == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: _green),
            SizedBox(width: 12),
            Expanded(child: Text('Semua stok barang masih aman.')),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFDDF4E8),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stok Menipis',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        'Ada $_lowCount barang yang stoknya hampir habis.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          for (final product in _lowStock) _lowStockItem(product),
        ],
      ),
    );
  }

  Widget _lowStockItem(Map<String, dynamic> product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
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
            child: const Icon(Icons.inventory_2_outlined, color: _green),
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
                  'Stok: ${product['stock']}',
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48, color: Color(0xFF6B7280)),
            const SizedBox(height: 12),
            Text(_error ?? 'Gagal memuat data', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _load(showLoading: true),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
