import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'websocket/websocket_client.dart';

typedef AlertCallback = void Function(Map<String, dynamic> alert);

/// Estado de la conexión en tiempo real
enum RealtimeMode { disconnected, connecting, webSocket, pollingFallback }

/// Servicio de sincronización y alertas en tiempo real híbrido:
/// 1. Conexión WebSocket STOMP nativa de latencia cero (/ws) hacia Spring Boot.
/// 2. Fallback adaptativo HTTP polling transparente ante microcortes o proxies restrictivos.
class RealtimeAlertService {
  RealtimeAlertService({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  final List<AlertCallback> _alertListeners = [];
  final List<VoidCallback> _incidentListeners = [];
  final ValueNotifier<RealtimeMode> connectionMode =
      ValueNotifier<RealtimeMode>(RealtimeMode.disconnected);

  PlatformWebSocket? _ws;
  StreamSubscription<String>? _wsMessageSub;
  StreamSubscription<dynamic>? _wsErrorSub;
  StreamSubscription<void>? _wsCloseSub;

  Timer? _pollingTimer;
  Timer? _reconnectTimer;
  bool _isDisposed = false;
  final Set<String> _knownIds = {};
  bool _initialized = false;
  int _reconnectAttempts = 0;

  void addAlertListener(AlertCallback listener) =>
      _alertListeners.add(listener);
  void removeAlertListener(AlertCallback listener) =>
      _alertListeners.remove(listener);

  void addIncidentListener(VoidCallback listener) =>
      _incidentListeners.add(listener);
  void removeIncidentListener(VoidCallback listener) =>
      _incidentListeners.remove(listener);

  void connect() {
    if (_isDisposed) return;
    _connectWebSocket();
  }

  /// Intenta conectar vía WebSocket nativo STOMP (/ws)
  Future<void> _connectWebSocket() async {
    if (_isDisposed) return;
    connectionMode.value = RealtimeMode.connecting;

    try {
      final wsUrl = _buildWebSocketUrl('/ws');
      _ws = await PlatformWebSocket.connect(wsUrl);

      _wsMessageSub = _ws?.onMessage.listen(
        _onWebSocketMessage,
        onError: (_) => _handleWebSocketFailure(),
      );

      _wsCloseSub = _ws?.onClose.listen((_) => _handleWebSocketFailure());
      _wsErrorSub = _ws?.onError.listen((_) => _handleWebSocketFailure());

      // Enviar Frame STOMP CONNECT
      _sendStompFrame('CONNECT', {
        'accept-version': '1.2,1.1,1.0',
        'heart-beat': '10000,10000',
      });

      _reconnectAttempts = 0;
    } catch (_) {
      _handleWebSocketFailure();
    }
  }

  void _onWebSocketMessage(String rawData) {
    if (_isDisposed) return;

    // Procesar frames STOMP (terminados en \x00)
    final frames = rawData.split('\x00');
    for (final frame in frames) {
      final trimmed = frame.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('CONNECTED')) {
        connectionMode.value = RealtimeMode.webSocket;
        _pollingTimer?.cancel(); // Apagar polling mientras WS esté activo

        // Suscribirse a los tópicos de incidentes y alertas
        _sendStompFrame('SUBSCRIBE', {
          'id': 'sub-incidents',
          'destination': '/topic/incidents',
        });

        _sendStompFrame('SUBSCRIBE', {
          'id': 'sub-alerts',
          'destination': '/topic/alerts',
        });

        // Una verificación inicial HTTP para sincronizar históricos
        if (!_initialized) {
          _checkNow();
        }
      } else if (trimmed.startsWith('MESSAGE')) {
        _handleStompMessage(trimmed);
      }
    }
  }

  void _handleStompMessage(String frame) {
    try {
      // Extraer el cuerpo JSON después de la doble línea nueva
      final parts = frame.split(RegExp(r'\r?\n\r?\n'));
      if (parts.length < 2) return;

      final body = parts.sublist(1).join('\n\n').trim();
      if (body.isEmpty) return;

      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final id = decoded['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _knownIds.add(id);
        }

        final priority = decoded['priority']?.toString().toUpperCase();
        final type = decoded['type']?.toString().toUpperCase();
        final isCritical =
            priority == 'CRITICAL' ||
            type == 'SOS' ||
            type == 'BOTON_PANICO' ||
            type == 'PANICO';

        if (isCritical) {
          for (final listener in List.of(_alertListeners)) {
            listener(decoded);
          }
        }

        for (final listener in List.of(_incidentListeners)) {
          listener();
        }
      }
    } catch (_) {}
  }

  void _sendStompFrame(
    String command,
    Map<String, String> headers, [
    String body = '',
  ]) {
    if (_ws?.isOpen != true) return;
    final buffer = StringBuffer()..writeln(command);
    headers.forEach((k, v) => buffer.writeln('$k:$v'));
    buffer.writeln(); // línea vacía obligatoria
    if (body.isNotEmpty) {
      buffer.write(body);
    }
    buffer.write('\x00');
    _ws?.send(buffer.toString());
  }

  void _handleWebSocketFailure() {
    if (_isDisposed) return;
    _cleanWebSocket();

    // Activar modo polling resiliente para garantizar que nunca se pierdan datos
    connectionMode.value = RealtimeMode.pollingFallback;
    _checkNow();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkNow(),
    );

    // Reintentar reconexión WebSocket con backoff exponencial
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final delaySeconds = (_reconnectAttempts * 4).clamp(4, 30);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_isDisposed && connectionMode.value != RealtimeMode.webSocket) {
        _connectWebSocket();
      }
    });
  }

  void _cleanWebSocket() {
    _wsMessageSub?.cancel();
    _wsErrorSub?.cancel();
    _wsCloseSub?.cancel();
    try {
      _ws?.close();
    } catch (_) {}
    _ws = null;
  }

  Future<void> _checkNow() async {
    if (_isDisposed) return;
    try {
      final url = _buildEndpoint('/api/Incidents');
      final response = await _client
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list =
            (decoded is Map<String, dynamic> ? decoded['data'] : decoded)
                as List? ??
            const [];

        bool hasNew = false;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty && !_knownIds.contains(id)) {
              if (_initialized) {
                hasNew = true;
                final priority = item['priority']?.toString().toUpperCase();
                final type = item['type']?.toString().toUpperCase();
                final isCritical =
                    priority == 'CRITICAL' ||
                    type == 'SOS' ||
                    type == 'BOTON_PANICO' ||
                    type == 'PANICO';

                if (isCritical) {
                  for (final listener in List.of(_alertListeners)) {
                    listener(item);
                  }
                }
              }
              _knownIds.add(id);
            }
          }
        }

        if (!_initialized) {
          _initialized = true;
        } else if (hasNew) {
          for (final listener in List.of(_incidentListeners)) {
            listener();
          }
        }
      }
    } catch (_) {}
  }

  String _buildWebSocketUrl(String path) {
    var base = baseUrl.trim();
    if (base.isEmpty || base == '/api') {
      if (!kIsWeb) {
        return 'wss://pa-definivitvo.onrender.com$path';
      }
      final host = Uri.base.host;
      final isSecure = Uri.base.scheme == 'https';
      final scheme = isSecure ? 'wss' : 'ws';
      final port = Uri.base.hasPort ? ':${Uri.base.port}' : '';
      return '$scheme://$host$port$path';
    }

    // Remover sub-ruta /api final para que el WebSocket apunte al endpoint raíz /ws
    base = base.replaceFirst(RegExp(r'/api/?$'), '');

    if (base.startsWith('https://')) {
      return base.replaceFirst('https://', 'wss://') + path;
    } else if (base.startsWith('http://')) {
      return base.replaceFirst('http://', 'ws://') + path;
    }

    return 'ws://$base$path';
  }

  Uri _buildEndpoint(String path) {
    var base = baseUrl.trim();
    if (base.isEmpty || base == '/api') {
      return Uri.base.resolve(path);
    }
    base = base.replaceFirst(RegExp(r'(?:/api)?/$|/api$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    if (base.startsWith('http://') || base.startsWith('https://')) {
      return Uri.parse('$base$cleanPath');
    }
    return Uri.base.resolve('$base$cleanPath');
  }

  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _reconnectTimer?.cancel();
    _cleanWebSocket();
    _client.close();
    connectionMode.dispose();
  }
}
