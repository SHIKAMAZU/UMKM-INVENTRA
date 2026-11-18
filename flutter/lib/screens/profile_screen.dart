import 'package:flutter/material.dart';

import '../services/session.dart';
import 'login_screen.dart';

const _dark = Color(0xFF0B5D4E);
const _green = Color(0xFF0E7A5F);
const _bg = Color(0xFFE6F7EF);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.session});

  final Session session;

  Future<void> _logout(BuildContext context) async {
    await session.clear();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => LoginScreen(session: session)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = session.user;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: _bg,
        foregroundColor: _dark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _header(user?.name, user?.email, user?.role),
          const SizedBox(height: 16),
          Row(
            children: [
              _miniStat(
                Icons.badge_outlined,
                'Role',
                (user?.role ?? '-').toUpperCase(),
              ),
              const SizedBox(width: 12),
              _miniStat(Icons.verified_user_outlined, 'Status', 'Aktif'),
            ],
          ),
          const SizedBox(height: 16),
          _infoCard(),
          const SizedBox(height: 16),
          _aboutCard(),
          const SizedBox(height: 20),
          _logoutButton(context),
        ],
      ),
    );
  }

  Widget _header(String? name, String? email, String? role) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_dark, _green],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0B5D4E),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 38,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 42, color: _green),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name ?? '-',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            email ?? '-',
            style: const TextStyle(color: Color(0xFFBFEAD8), fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  (role ?? '-').toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String label, String value) {
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
            Icon(icon, color: _green, size: 22),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard() {
    final user = session.user;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          _infoTile(Icons.alternate_email, 'Email', user?.email ?? '-'),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _infoTile(Icons.person_outline, 'Nama', user?.name ?? '-'),
          const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
          _infoTile(
            Icons.tag,
            'ID Pengguna',
            user?.id.toString() ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: _green),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _aboutCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const ListTile(
        leading: Icon(Icons.storefront_outlined, color: _green),
        title: Text(
          'INVENTRA',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('Sistem Manajemen Stok Barang Toko • v1.0.0'),
      ),
    );
  }

  Widget _logoutButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: () async {
        final sure = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Keluar'),
            content: const Text('Yakin ingin keluar dari aplikasi?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Keluar'),
              ),
            ],
          ),
        );

        if (sure == true && context.mounted) {
          await _logout(context);
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text('Keluar'),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
