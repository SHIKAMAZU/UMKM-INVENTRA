import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.session});

  final Session session;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _categories = [];

  bool get _isAdmin => widget.session.user?.role == 'admin';

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
      final json = await ApiClient(widget.session).get('/api/categories');
      if (!mounted) return;
      setState(() {
        _categories = (json['data'] as List).cast<Map<String, dynamic>>();
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
        _error = 'Gagal memuat kategori';
        _loading = false;
      });
    }
  }

  Future<void> _form([Map<String, dynamic>? category]) async {
    final editing = category != null;
    final count = (category?['product_count'] as num?)?.toInt() ?? 0;
    final name = TextEditingController(text: '${category?['name'] ?? ''}');
    final description = TextEditingController(
      text: '${category?['description'] ?? ''}',
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
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
                        Icons.category,
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
                            editing ? 'Edit Kategori' : 'Tambah Kategori',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            editing
                                ? 'Perbarui nama atau deskripsi kategori'
                                : 'Buat kategori baru untuk produk',
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
                            count == 0
                                ? 'Belum ada produk di kategori ini'
                                : '$count produk terdaftar di kategori ini',
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
                    'Nama kategori',
                    Icons.label_outline,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _fieldDecoration(
                    'Deskripsi (opsional)',
                    Icons.notes,
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
                          if (name.text.trim().isEmpty) {
                            _showMessage('Nama kategori wajib diisi');
                            return;
                          }
                          final text = description.text.trim();
                          final body = {
                            'name': name.text.trim(),
                            'description': text.isEmpty ? null : text,
                          };
                          try {
                            final api = ApiClient(widget.session);
                            if (editing) {
                              await api.put(
                                '/api/categories/${category['id']}',
                                body,
                              );
                            } else {
                              await api.post('/api/categories', body);
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
    description.dispose();

    if (saved == true) {
      _showMessage(editing ? 'Kategori diperbarui' : 'Kategori ditambahkan');
      await _load();
    }
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _delete(Map<String, dynamic> category) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kategori'),
        content: Text('Hapus ${category['name']}?'),
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
      await ApiClient(
        widget.session,
      ).delete('/api/categories/${category['id']}');
      _showMessage('Kategori dihapus');
      await _load();
    } on ApiException catch (error) {
      _showMessage(error.message);
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
        title: const Text('Kategori'),
        backgroundColor: _bg,
        foregroundColor: _dark,
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              onPressed: () => _form(),
              icon: const Icon(Icons.add),
              tooltip: 'Tambah Kategori',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: _load,
              child: _categories.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.category_outlined, size: 48),
                        SizedBox(height: 12),
                        Text('Belum ada kategori', textAlign: TextAlign.center),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _categories.length,
                      itemBuilder: (_, index) => _item(_categories[index]),
                    ),
            ),
    );
  }

  Widget _item(Map<String, dynamic> category) {
    final count = (category['product_count'] as num?)?.toInt() ?? 0;
    final description = '${category['description'] ?? '-'}';

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
            child: const Icon(Icons.category, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${category['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
              color: const Color(0xFFDDF4E8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count produk',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _green,
              ),
            ),
          ),
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) =>
                  value == 'edit' ? _form(category) : _delete(category),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
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
          Text(_error ?? 'Gagal memuat kategori'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
