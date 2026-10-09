import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required String baseUrl, http.Client? client})
    : _baseUrl = _normalizeBaseUrl(baseUrl),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  String? token;

  void close() => _client.close();

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim().replaceFirst(RegExp(r'/+$'), '');
    if (trimmed.isEmpty) {
      return '';
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasAuthority ||
        !const {'http', 'https'}.contains(uri.scheme)) {
      throw ArgumentError.value(
        value,
        'baseUrl',
        'Debe ser una URL HTTP o HTTPS',
      );
    }
    return trimmed;
  }

  Uri endpoint(String path) {
    if (_baseUrl.isEmpty) {
      throw const ApiException(
        'Configura la URL de la API con --dart-define=API_BASE_URL=https://tu-api/api',
      );
    }
    return Uri.parse('$_baseUrl/${path.replaceFirst(RegExp(r'^/+'), '')}');
  }

  Future<dynamic> get(String path) => _send('GET', path);

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);

  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = endpoint(path);
    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) {
      headers['Content-Type'] = 'application/json; charset=utf-8';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    late final http.Response response;
    try {
      final request = http.Request(method, uri)..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }
      final streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 20));
      response = await http.Response.fromStream(streamed);
    } on Exception catch (error) {
      throw ApiException('No fue posible conectar con la API: $error');
    }

    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw ApiException(
          'La API devolvió una respuesta no válida (HTTP ${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    }

    final envelope = decoded is Map<String, dynamic> ? decoded : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = envelope?['message']?.toString();
      throw ApiException(
        message?.isNotEmpty == true
            ? message!
            : 'La API respondió con HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    if (envelope != null && envelope['success'] == false) {
      throw ApiException(
        envelope['message']?.toString() ?? 'La solicitud no pudo completarse',
        statusCode: response.statusCode,
      );
    }
    return envelope != null && envelope.containsKey('data')
        ? envelope['data']
        : decoded;
  }
}
