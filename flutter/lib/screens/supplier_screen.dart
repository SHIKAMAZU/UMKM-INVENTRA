import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/session.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key, required this.session});

  final Session session;

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _suppliers = [];

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
      final json = await ApiClient(widget.session).get('/api/suppliers');
      if (!mounted) return;
      setState(() {
        _suppliers = (json['data'] as List).cast<Map<String, dynamic>>();
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
        _error = 'Gagal memuat data supplier';
        _loading = false;
      });
    }
  }

  Future<void> _form([Map<String, dynamic>? supplier]) async {
    final editing = supplier != null;
    final name = TextEditingController(text: '${supplier?['name'] ?? ''}');
    final phone = TextEditingController(text: '${supplier?['phone'] ?? ''}');
    final email = TextEditingController(text: '${supplier?['email'] ?? ''}');
    final address = TextEditingController(
      text: '${supplier?['address'] ?? ''}',
    );

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
                        Icons.local_shipping,
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
                            editing ? 'Edit Supplier' : 'Tambah Supplier',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              color: _dark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            editing
                                ? 'Perbarui data supplier'
                                : 'Lengkapi data supplier baru',
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
                const SizedBox(height: 20),
                TextField(
                  controller: name,
                  textCapitalization: TextCapitalization.words,
                  decoration: _fieldDecoration(
                    'Nama supplier',
                    Icons.storefront_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: _fieldDecoration('Telepon', Icons.phone_outlined),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _fieldDecoration('Email', Icons.mail_outline),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: address,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _fieldDecoration(
                    'Alamat',
                    Icons.location_on_outlined,
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
                            _showMessage('Nama supplier wajib diisi');
                            return;
                          }
                          String? optional(TextEditingController controller) {
                            final value = controller.text.trim();
                            return value.isEmpty ? null : value;
                          }

                          final body = {
                            'name': name.text.trim(),
                            'phone': optional(phone),
                            'email': optional(email),
                            'address': optional(address),
                          };
                          try {
                            final api = ApiClient(widget.session);
                            if (editing) {
                              await api.put(
                                '/api/suppliers/${supplier['id']}',
                                body,
                              );
                            } else {
                              await api.post('/api/suppliers', body);
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
    phone.dispose();
    email.dispose();
    address.dispose();

    if (saved == true) {
      _showMessage(editing ? 'Supplier diperbarui' : 'Supplier ditambahkan');
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

  Future<void> _delete(Map<String, dynamic> supplier) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Hapus ${supplier['name']}?'),
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
      ).delete('/api/suppliers/${supplier['id']}');
      _showMessage('Supplier dihapus');
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
        title: const Text('Data Supplier'),
        backgroundColor: _bg,
        foregroundColor: _dark,
        elevation: 0,
        actions: [
          if (_isAdmin)
            IconButton(
              onPressed: () => _form(),
              icon: const Icon(Icons.add),
              tooltip: 'Tambah Supplier',
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: _load,
              child: _suppliers.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        SizedBox(height: 100),
                        Icon(Icons.local_shipping_outlined, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada data supplier',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _suppliers.length,
                      itemBuilder: (_, index) => _item(_suppliers[index]),
                    ),
            ),
    );
  }

  Widget _item(Map<String, dynamic> supplier) {
    final phone = '${supplier['phone'] ?? '-'}';
    final address = '${supplier['address'] ?? '-'}';

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
            child: const Icon(Icons.local_shipping, color: _green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${supplier['name']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Text(
                  address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          if (_isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) =>
                  value == 'edit' ? _form(supplier) : _delete(supplier),
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
          Text(_error ?? 'Gagal memuat data supplier'),
          const SizedBox(height: 16),
          FilledButton(onPressed: _load, child: const Text('Coba Lagi')),
        ],
      ),
    );
  }
}
