import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import 'notification_screen.dart';
import 'sale_screen.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key, required this.session});

  final Session session;

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  static const _filters = ['Semua', 'Pembelian', 'Penjualan', 'Penyesuaian'];

  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  String _filter = 'Semua';
  List<Map<String, dynamic>> _items = [];

  bool get _isAdmin => widget.session.user?.role == 'admin';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final api = ApiClient(widget.session);
      final items = <Map<String, dynamic>>[];

      final saleJson = await api.get('/api/sales?limit=100');
      for (final sale
          in (saleJson['data'] as List).cast<Map<String, dynamic>>()) {
        final id = (sale['id'] as num).toInt();
        items.add({
          'type': 'sale',
          'category': 'Penjualan',
          'title': 'Penjualan',
          'code': 'INV-${id.toString().padLeft(5, '0')}',
          'date': DateTime.tryParse('${sale['created_at']}')?.toLocal(),
          'amount': (sale['total'] as num).toDouble(),
          'status': 'Selesai',
          'product':
              '${sale['item_count']} jenis • ${sale['total_quantity']} barang',
          'note': null,
        });
      }

      if (_isAdmin) {
        final movementJson = await api.get('/api/stock-movements?limit=100');
        for (final move
            in (movementJson['data'] as List).cast<Map<String, dynamic>>()) {
          final type = '${move['type']}';
          if (type != 'in' && type != 'adjust') continue;
          final isIn = type == 'in';
          final id = (move['id'] as num).toInt();
          items.add({
            'type': isIn ? 'in' : 'adjust',
            'category': isIn ? 'Pembelian' : 'Penyesuaian',
            'title': isIn ? 'Pembelian' : 'Penyesuaian Stok',
            'code': '${isIn ? 'PO' : 'ADJ'}-${id.toString().padLeft(5, '0')}',
            'date': DateTime.tryParse('${move['created_at']}')?.toLocal(),
            'amount': 0.0,
            'status': isIn ? 'Diproses' : 'Info',
            'product': '${move['product_name']} • ${move['quantity']} pcs',
            'note': move['note'],
          });
        }
      }

      items.sort((a, b) {
        final dateA = a['date'] as DateTime?;
        final dateB = b['date'] as DateTime?;
        if (dateA == null || dateB == null) return 0;
        return dateB.compareTo(dateA);
      });

      if (!mounted) return;
      setState(() {
        _items = items;
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
        _error = 'Gagal memuat transaksi';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final keyword = _search.text.trim().toLowerCase();
    return _items.where((item) {
      final matchFilter = _filter == 'Semua' || item['category'] == _filter;
      final text = '${item['title']} ${item['code']} ${item['product']}'
          .toLowerCase();
      final matchSearch = keyword.isEmpty || text.contains(keyword);
      return matchFilter && matchSearch;
    }).toList();
  }

  Future<void> _newSale() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SaleScreen(session: widget.session),
      ),
    );
    if (mounted) await _load();
  }

  void _showDetail(Map<String, dynamic> item) {
    final rows = [
      'Kode: ${item['code']}',
      'Tanggal: ${_formatDate(item['date'] as DateTime?)}',
      '${item['product']}',
      'Status: ${item['status']}',
      if ((item['amount'] as num) > 0)
        'Total: ${_rupiah(item['amount'] as num)}',
      if ('${item['note'] ?? ''}'.isNotEmpty) 'Catatan: ${item['note']}',
    ];

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item['title']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final row in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(row),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transaksi',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0B2B26),
                              ),
                            ),
                            Text(
                              'Lihat riwayat transaksi barang di toko Anda',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4B5563),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Cari transaksi...',
                            hintStyle: const TextStyle(fontSize: 13),
                            prefixIcon: const Icon(Icons.search, size: 20),
                            filled: true,
                            fillColor: const Color(0xFFDDF4E8),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in _filters)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _filterChip(filter),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _errorView()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: filtered.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.all(20),
                              children: const [
                                SizedBox(height: 80),
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Tidak ada transaksi',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                              itemCount: filtered.length,
                              itemBuilder: (_, index) => _item(filtered[index]),
                            ),
                    ),
            ),
            if (!_loading && _error == null) _summary(filtered.length),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(color: _dark, shape: BoxShape.circle),
          child: const Icon(Icons.storefront, color: Colors.white, size: 30),
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
        IconButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => NotificationScreen(session: widget.session),
              ),
            );
          },
          icon: const Icon(Icons.notifications_none, size: 28, color: _dark),
        ),
        IconButton(
          onPressed: _newSale,
          icon: const Icon(Icons.add_circle_outline, size: 28, color: _dark),
          tooltip: 'Transaksi Baru',
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _dark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? _dark : const Color(0xFFD1E7DC)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : _dark,
          ),
        ),
      ),
    );
  }

  Widget _item(Map<String, dynamic> item) {
    final type = '${item['type']}';
    final icon = type == 'sale'
        ? Icons.shopping_cart
        : type == 'in'
        ? Icons.inventory_2
        : Icons.settings;

    return GestureDetector(
      onTap: () => _showDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: _bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _green, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item['title']}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Text(
                    '${item['code']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    _formatDate(item['date'] as DateTime?),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusPill('${item['status']}'),
                const SizedBox(height: 6),
                Text(
                  _rupiah(item['amount'] as num),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final Color bg;
    final Color fg;
    final IconData icon;

    if (status == 'Selesai') {
      bg = const Color(0xFFDDF4E8);
      fg = _green;
      icon = Icons.check_circle;
    } else if (status == 'Diproses') {
      bg = const Color(0xFFE0F0FE);
      fg = const Color(0xFF1D6FD6);
      icon = Icons.schedule;
    } else {
      bg = const Color(0xFFF1E8FD);
      fg = const Color(0xFF7C3AED);
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summary(int total) {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDDF4E8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: _dark, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Transaksi',
                  style: TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
                ),
                Text(
                  '$total Transaksi',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: const Color(0xFFB7DCCB)),
          const SizedBox(width: 12),
          const Icon(Icons.calendar_today, size: 16, color: _dark),
          const SizedBox(width: 6),
          Text(
            '${months[now.month - 1]} ${now.year}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _dark,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    String two(int number) => number.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} • '
        '${two(date.hour)}:${two(date.minute)}';
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

  Widget _errorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: Color(0xFF6B7280)),
          const SizedBox(height: 12),
          Text(_error ?? 'Gagal memuat transaksi'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
