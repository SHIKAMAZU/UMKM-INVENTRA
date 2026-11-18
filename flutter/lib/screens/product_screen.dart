import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import '../services/session.dart';
import 'product_detail_screen.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.session});

  final Session session;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];

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
      final json = await api.get('/api/products?limit=100');
      final categoryJson = await api.get('/api/categories');
      if (!mounted) return;
      setState(() {
        _products = (json['data'] as List).cast<Map<String, dynamic>>();
        _categories = (categoryJson['data'] as List)
            .cast<Map<String, dynamic>>();
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

  List<Map<String, dynamic>> get _filtered {
    final keyword = _search.text.trim().toLowerCase();
    if (keyword.isEmpty) return _products;
    return _products.where((product) {
      final name = '${product['name']}'.toLowerCase();
      final sku = '${product['sku']}'.toLowerCase();
      return name.contains(keyword) || sku.contains(keyword);
    }).toList();
  }

  Future<bool> _form([
    Map<String, dynamic>? product,
    String? initialCategory,
  ]) async {
    final editing = product != null;
    final stockNow = (product?['stock'] as num?)?.toInt() ?? 0;
    final name = TextEditingController(text: '${product?['name'] ?? ''}');
    final sku = TextEditingController(text: '${product?['sku'] ?? ''}');
    final price = TextEditingController(text: '${product?['price'] ?? ''}');
    final stock = TextEditingController(text: '${product?['stock'] ?? 0}');
    final minStock = TextEditingController(
      text: '${product?['min_stock'] ?? 5}',
    );
    final category = TextEditingController(
      text: '${product?['category_name'] ?? initialCategory ?? ''}',
    );
    final pickedImage = ValueNotifier<XFile?>(null);
    final imagePicker = ImagePicker();

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _bg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.inventory_2,
                        color: _green,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            editing ? 'Edit Produk' : 'Tambah Produk',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            editing
                                ? 'Perbarui detail produk'
                                : 'Lengkapi detail produk baru',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (editing) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: _green,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Stok saat ini $stockNow. Ubah lewat menu Kelola Stok.',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _dark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(
                    'Nama produk',
                    Icons.sell_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sku,
                  textCapitalization: TextCapitalization.characters,
                  decoration: _fieldDecoration('SKU', Icons.qr_code_2),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(
                    'Harga',
                    Icons.payments_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: category,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(
                    'Kategori',
                    Icons.category_outlined,
                    hint: 'Pilih di bawah atau ketik baru',
                    helper: 'Kategori baru otomatis dibuat',
                  ),
                ),
                if (_categories.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final item in _categories)
                        ActionChip(
                          label: Text('${item['name']}'),
                          onPressed: () => category.text = '${item['name']}',
                          backgroundColor: _bg,
                          side: BorderSide.none,
                          labelStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _dark,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      ValueListenableBuilder<XFile?>(
                        valueListenable: pickedImage,
                        builder: (context, file, _) {
                          final existing = editing ? _imageUrl(product) : null;
                          if (file != null) {
                            return const Icon(
                              Icons.check_circle,
                              color: _green,
                              size: 34,
                            );
                          }
                          if (existing != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                existing,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.broken_image_outlined,
                                  color: _green,
                                  size: 30,
                                ),
                              ),
                            );
                          }
                          return const Icon(
                            Icons.image_outlined,
                            color: _green,
                            size: 34,
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ValueListenableBuilder<XFile?>(
                          valueListenable: pickedImage,
                          builder: (context, file, _) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                file == null
                                    ? 'Belum ada gambar dipilih'
                                    : file.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: _dark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final file = await imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 85,
                                      maxWidth: 1200,
                                    );
                                    if (file != null) {
                                      pickedImage.value = file;
                                    }
                                  } catch (_) {
                                    _showMessage('Gagal memilih gambar');
                                  }
                                },
                                icon: const Icon(
                                  Icons.photo_library_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  file == null
                                      ? 'Pilih Gambar'
                                      : 'Ganti Gambar',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!editing) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: stock,
                    keyboardType: TextInputType.number,
                    decoration: _fieldDecoration(
                      'Stok awal',
                      Icons.add_box_outlined,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: minStock,
                  keyboardType: TextInputType.number,
                  decoration: _fieldDecoration(
                    'Stok minimal',
                    Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _dark,
                          minimumSize: const Size.fromHeight(50),
                          side: const BorderSide(color: Color(0xFFD1E7DD)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          if (name.text.trim().isEmpty ||
                              sku.text.trim().isEmpty) {
                            _showMessage('Nama dan SKU wajib diisi');
                            return;
                          }
                          final categoryName = category.text.trim();
                          if (categoryName.isEmpty) {
                            _showMessage('Kategori wajib diisi');
                            return;
                          }
                          try {
                            final api = ApiClient(widget.session);
                            var categoryId = _findCategoryId(categoryName);
                            if (categoryId == null) {
                              final created = await api.post(
                                '/api/categories',
                                {'name': categoryName},
                              );
                              final data =
                                  created['data'] as Map<String, dynamic>;
                              categoryId = (data['id'] as num).toInt();
                              _categories.add({...data, 'product_count': 0});
                            }
                            final body = <String, dynamic>{
                              'category_id': categoryId,
                              'sku': sku.text.trim(),
                              'name': name.text.trim(),
                              'price': int.tryParse(price.text) ?? 0,
                              'min_stock': int.tryParse(minStock.text) ?? 0,
                              if (!editing)
                                'stock': int.tryParse(stock.text) ?? 0,
                            };

                            int productId;
                            if (editing) {
                              productId = (product['id'] as num).toInt();
                              await api.put('/api/products/$productId', body);
                            } else {
                              final created = await api.post(
                                '/api/products',
                                body,
                              );
                              productId =
                                  ((created['data']
                                              as Map<String, dynamic>)['id']
                                          as num)
                                      .toInt();
                            }

                            final picked = pickedImage.value;
                            if (picked != null) {
                              final bytes = await picked.readAsBytes();
                              await api.uploadBytes(
                                '/api/products/$productId/image',
                                'image',
                                bytes,
                                picked.name,
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } on ApiException catch (error) {
                            _showMessage(error.message);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _green,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    name.dispose();
    sku.dispose();
    price.dispose();
    stock.dispose();
    minStock.dispose();
    category.dispose();
    pickedImage.dispose();

    if (saved == true) {
      _showMessage(editing ? 'Produk diperbarui' : 'Produk ditambahkan');
      await _load();
    }
    return saved == true;
  }

  InputDecoration _fieldDecoration(
    String label,
    IconData icon, {
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  int? _findCategoryId(String name) {
    final target = name.trim().toLowerCase();
    for (final category in _categories) {
      if ('${category['name']}'.trim().toLowerCase() == target) {
        return (category['id'] as num).toInt();
      }
    }
    return null;
  }

  String? _imageUrl(Map<String, dynamic> product) {
    final url = '${product['image_url'] ?? ''}'.trim();
    if (url.isEmpty) return null;
    return url.startsWith('http') ? url : '${ApiConfig.baseUrl}$url';
  }

  Widget _thumbnail(Map<String, dynamic> product) {
    final url = _imageUrl(product);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 48,
        height: 48,
        color: _bg,
        child: url == null
            ? const Icon(Icons.inventory_2, color: _green)
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image_outlined, color: _green),
              ),
      ),
    );
  }

  Future<bool> _delete(Map<String, dynamic> product) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Hapus ${product['name']}?'),
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

    if (sure != true) return false;

    try {
      await ApiClient(widget.session).delete('/api/products/${product['id']}');
      _showMessage('Produk dihapus');
      await _load();
      return true;
    } on ApiException catch (error) {
      _showMessage(error.message);
      return false;
    }
  }

  Future<void> _openDetail(Map<String, dynamic> product) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          session: widget.session,
          product: product,
          onEdit: (item) => _form(item),
          onDelete: _delete,
        ),
      ),
    );
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
        title: const Text('Produk'),
        backgroundColor: _bg,
        foregroundColor: _dark,
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              onPressed: () => _form(),
              icon: const Icon(Icons.add),
              tooltip: 'Tambah Produk',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau SKU',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(20),
                            children: const [
                              SizedBox(height: 100),
                              Icon(Icons.inventory_2_outlined, size: 48),
                              SizedBox(height: 12),
                              Text(
                                'Produk tidak ditemukan',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _filtered.length,
                            itemBuilder: (_, index) => _item(_filtered[index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _item(Map<String, dynamic> product) {
    final stock = (product['stock'] as num).toInt();
    final minStock = (product['min_stock'] as num).toInt();
    final price = (product['price'] as num).toInt();
    final low = stock <= minStock;

    return GestureDetector(
      onTap: () => _openDetail(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _thumbnail(product),
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
                    '${product['sku']} • ${product['category_name']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    'Rp $price',
                    style: const TextStyle(
                      fontSize: 13,
                      color: _dark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: low
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFDDF4E8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stok $stock',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: low ? const Color(0xFFB91C1C) : _green,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'min $minStock',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            if (_isAdmin)
              PopupMenuButton<String>(
                onSelected: (value) =>
                    value == 'edit' ? _form(product) : _delete(product),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              ),
          ],
        ),
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
          Text(_error ?? 'Gagal memuat produk'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
