import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'session.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.errors]);

  final String message;
  final Map<String, dynamic>? errors;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this.session);

  final Session session;

  Future<Map<String, dynamic>> get(String path) {
    return _send('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> body) {
    return _send('PUT', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send('DELETE', path);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (session.token != null && session.token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${session.token}';
    }

    http.Response response;
    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers);
      } else if (method == 'PUT') {
        response = await http.put(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      } else {
        response = await http.post(
          uri,
          headers: headers,
          body: jsonEncode(body ?? {}),
        );
      }
    } catch (_) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend sudah berjalan.',
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak valid (${response.statusCode})');
    }

    final isSuccess =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json['success'] == true;

    if (!isSuccess) {
      final errors = json['errors'];
      throw ApiException(
        json['message'] as String? ??
            'Terjadi kesalahan (${response.statusCode})',
        errors is Map<String, dynamic> ? errors : null,
      );
    }

    return json;
  }

  Future<Map<String, dynamic>> uploadBytes(
    String path,
    String field,
    Uint8List bytes,
    String filename,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}$path'),
    );

    if (session.token != null && session.token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${session.token}';
    }
    request.files.add(
      http.MultipartFile.fromBytes(field, bytes, filename: filename),
    );

    http.Response response;
    try {
      final streamed = await request.send();
      response = await http.Response.fromStream(streamed);
    } catch (_) {
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend sudah berjalan.',
      );
    }

    return _parse(response);
  }

  Map<String, dynamic> _parse(http.Response response) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak valid (${response.statusCode})');
    }

    final isSuccess =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        json['success'] == true;

    if (!isSuccess) {
      final errors = json['errors'];
      throw ApiException(
        json['message'] as String? ??
            'Terjadi kesalahan (${response.statusCode})',
        errors is Map<String, dynamic> ? errors : null,
      );
    }

    return json;
  }
}
