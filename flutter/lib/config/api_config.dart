import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _envBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    final configured = _envBaseUrl.trim();
    if (configured.isNotEmpty) {
      return configured.replaceFirst(RegExp(r'/+$'), '');
    }
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
}
