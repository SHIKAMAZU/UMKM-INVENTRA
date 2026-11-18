import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session.dart';
import 'home_screen.dart';
import 'register_screen.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _mint = Color(0xFFD7F7E8);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.session});

  final Session session;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading || !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService(ApiClient(widget.session))
          .login(_emailController.text.trim(), _passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(session: widget.session),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegister() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => RegisterScreen(session: widget.session),
      ),
    );
    if (email != null && mounted) {
      _emailController.text = email;
      _showMessage('Registrasi berhasil. Silakan masuk.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _input(String hint, IconData icon) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _dark),
      filled: true,
      fillColor: const Color(0xFFF4F7F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: _green, width: 2),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_mint, Color(0xFF9EE6CD)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: _circle(220, const Color(0x330B5D4E)),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _circle(260, const Color(0x220B5D4E)),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A0B5D4E),
                            blurRadius: 40,
                            offset: Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: _mint,
                                  borderRadius: BorderRadius.circular(26),
                                ),
                                child: const Icon(
                                  Icons.storefront,
                                  size: 48,
                                  color: _dark,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Text(
                              'INVENTRA',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                color: _dark,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Sistem Manajemen Stok Barang Toko',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: Color(0xFF55706A),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(color: Color(0xFFD5E3DF)),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    Icons.inventory_2_outlined,
                                    color: _green,
                                  ),
                                ),
                                Expanded(
                                  child: Divider(color: Color(0xFFD5E3DF)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: _input('Email', Icons.mail_outline),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return 'Email wajib diisi';
                                if (!email.contains('@')) {
                                  return 'Format email tidak valid';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: _input(
                                'Password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: _dark,
                                  ),
                                ),
                              ),
                              validator: (value) =>
                                  (value == null || value.isEmpty)
                                  ? 'Password wajib diisi'
                                  : null,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              style: FilledButton.styleFrom(
                                backgroundColor: _green,
                                minimumSize: const Size.fromHeight(54),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                const Text(
                                  'Belum punya akun?',
                                  style: TextStyle(color: Color(0xFF55706A)),
                                ),
                                TextButton(
                                  onPressed: _loading ? null : _openRegister,
                                  child: const Text(
                                    'Daftar',
                                    style: TextStyle(
                                      color: _green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
