import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';
import 'sales_history_screen.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key, required this.session});

  final Session session;

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final _qty = TextEditingController(text: '1');
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  final List<Map<String, dynamic>> _cart = [];
  int? _selectedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _qty.dispose();
    super.dispose();
  }

  Map<String, dynamic>? get _selected {
    for (final product in _products) {
      if ((product['id'] as num).toInt() == _selectedId) return product;
    }
    return null;
  }

  double get _total => _cart.fold(
    0,
    (sum, item) => sum + (item['price'] as double) * (item['quantity'] as int),
  );

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final json = await ApiClient(
        widget.session,
      ).get('/api/products?limit=100');
      final list = (json['data'] as List).cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        _products = list;
        final exists = list.any((p) => (p['id'] as num).toInt() == _selectedId);
        if (!exists) {
          _selectedId = list.isEmpty ? null : (list.first['id'] as num).toInt();
        }
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
        _error = 'Gagal memuat produk';
        _loading = false;
      });
    }
  }

  void _changeQty(int delta) {
    final current = int.tryParse(_qty.text) ?? 1;
    final next = (current + delta).clamp(1, 9999);
    _qty.text = '$next';
  }

  void _addToCart() {
    final product = _selected;
    if (product == null) {
      _showMessage('Pilih produk terlebih dahulu');
      return;
    }

    final quantity = int.tryParse(_qty.text) ?? 0;
    final id = (product['id'] as num).toInt();
    final stock = (product['stock'] as num).toInt();
    final existing = _cart.where((item) => item['product_id'] == id).toList();
    final inCart = existing.isEmpty ? 0 : existing.first['quantity'] as int;

    if (quantity <= 0) {
      _showMessage('Jumlah harus lebih dari 0');
      return;
    }
    if (quantity + inCart > stock) {
      _showMessage('Stok tidak cukup. Tersisa ${stock - inCart}');
      return;
    }

    setState(() {
      if (existing.isEmpty) {
        _cart.add({
          'product_id': id,
          'name': product['name'],
          'price': (product['price'] as num).toDouble(),
          'quantity': quantity,
        });
      } else {
        existing.first['quantity'] = inCart + quantity;
      }
      _qty.text = '1';
    });
  }

  Future<void> _submit() async {
    if (_cart.isEmpty) {
      _showMessage('Keranjang masih kosong');
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiClient(widget.session).post('/api/sales', {
        'items': _cart
            .map(
              (item) => {
                'product_id': item['product_id'],
                'quantity': item['quantity'],
              },
            )
            .toList(),
      });
      if (!mounted) return;
      _showMessage('Transaksi penjualan berhasil');
      setState(() => _cart.clear());
      await _load();
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Gagal menyimpan transaksi');
    } finally {
      if (mounted) setState(() => _saving = false);
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
        backgroundColor: _bg,
        foregroundColor: _dark,
        elevation: 0,
        title: const Text(
          'Transaksi Baru',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SalesHistoryScreen(session: widget.session),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Riwayat Penjualan',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _productCard(),
                const SizedBox(height: 16),
                _cartCard(),
              ],
            ),
    );
  }

  Widget _productCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.add_shopping_cart,
                  color: _green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tambah Barang',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Pilih produk dan jumlahnya',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<int>(
            initialValue: _selectedId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Produk',
              filled: true,
              fillColor: _bg,
              prefixIcon: const Icon(Icons.inventory_2_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            items: [
              for (final product in _products)
                DropdownMenuItem<int>(
                  value: (product['id'] as num).toInt(),
                  child: Text(
                    '${product['name']} (stok ${product['stock']})',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) => setState(() => _selectedId = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _qtyStepper()),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _addToCart,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  minimumSize: const Size(0, 52),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Tambah'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyStepper() {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _changeQty(-1),
            icon: const Icon(Icons.remove, size: 18),
            color: _green,
          ),
          Expanded(
            child: TextField(
              controller: _qty,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              decoration: const InputDecoration(
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _changeQty(1),
            icon: const Icon(Icons.add, size: 18),
            color: _green,
          ),
        ],
      ),
    );
  }

  Widget _cartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_cart, color: _green, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Keranjang',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              Text(
                '${_cart.length} item',
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_cart.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    size: 40,
                    color: Color(0xFF9CA3AF),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Keranjang masih kosong',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                  ),
                ],
              ),
            )
          else ...[
            for (var i = 0; i < _cart.length; i++) _cartItem(i),
            const Divider(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                Text(
                  _rupiah(_total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: _dark,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving || _cart.isEmpty ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Simpan Transaksi'),
          ),
        ],
      ),
    );
  }

  Widget _cartItem(int index) {
    final item = _cart[index];
    final quantity = item['quantity'] as int;
    final price = item['price'] as double;
    final subtotal = price * quantity;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FBF8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2, color: _green, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['name']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '$quantity x ${_rupiah(price)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Text(
            _rupiah(subtotal),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          IconButton(
            onPressed: () => setState(() => _cart.removeAt(index)),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            tooltip: 'Hapus',
          ),
        ],
      ),
    );
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
          Text(_error ?? 'Gagal memuat produk'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
