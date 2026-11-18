import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class Session {
  String? _token;
  User? _user;

  String? get token => _token;
  User? get user => _user;

  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _user != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('token');

    final id = prefs.getInt('user_id');
    final name = prefs.getString('user_name');
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_role');

    if (id != null && name != null && email != null && role != null) {
      _user = User(id: id, name: name, email: email, role: role);
    }
  }

  Future<void> save(String token, User user) async {
    _token = token;
    _user = user;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
    await prefs.setInt('user_id', user.id);
    await prefs.setString('user_name', user.name);
    await prefs.setString('user_email', user.email);
    await prefs.setString('user_role', user.role);
  }

  Future<void> clear() async {
    _token = null;
    _user = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_id');
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_role');
  }
}
