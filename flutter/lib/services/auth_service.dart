import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this.api);

  final ApiClient api;

  Future<User> login(String email, String password) async {
    final json = await api.post('/api/auth/login', {
      'email': email,
      'password': password,
    });

    final data = json['data'] as Map<String, dynamic>;
    final token = data['token'] as String;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);

    await api.session.save(token, user);
    return user;
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await api.post('/api/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
  }
}
