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
  ApiClient({
    required String baseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 20),
  })
    : _baseUrl = _normalizeBaseUrl(baseUrl),
      _client = client ?? http.Client();

  final String _baseUrl;
  final http.Client _client;
  final Duration requestTimeout;
  String? token;
  Future<void> Function()? onUnauthorized;

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
          .timeout(requestTimeout);
      response = await http.Response.fromStream(streamed);
    } on Exception catch (error) {
      throw ApiException('No fue posible conectar con la API: $error');
    }

    String? sessionCleanupError;
    if (response.statusCode == 401 && token != null && onUnauthorized != null) {
      try {
        await onUnauthorized!();
      } on Exception catch (error) {
        sessionCleanupError = error.toString();
      }
    }

    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        throw ApiException(
          [
            'La API devolvió una respuesta no válida (HTTP ${response.statusCode})',
            if (sessionCleanupError != null)
              'No se pudo limpiar la sesión local: $sessionCleanupError',
          ].join('. '),
          statusCode: response.statusCode,
        );
      }
    }

    final envelope = decoded is Map<String, dynamic> ? decoded : null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      var message =
          envelope?['message']?.toString() ??
          'La API respondió con HTTP ${response.statusCode}';
      if (message.isEmpty) {
        message = 'La API respondió con HTTP ${response.statusCode}';
      }
      if (sessionCleanupError != null) {
        message =
            '$message. No se pudo limpiar la sesión local: $sessionCleanupError';
      }
      throw ApiException(message, statusCode: response.statusCode);
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
