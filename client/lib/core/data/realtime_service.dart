import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

typedef AlertCallback = void Function(Map<String, dynamic> alert);

/// Servicio de alertas y notificaciones en tiempo real vía WebSockets (con reconexión automática).
class RealtimeAlertService {
  RealtimeAlertService({required this.baseUrl});

  final String baseUrl;
  final List<AlertCallback> _alertListeners = [];
  final List<VoidCallback> _incidentListeners = [];

  web.WebSocket? _socket;
  Timer? _reconnectTimer;
  bool _isDisposed = false;

  void addAlertListener(AlertCallback listener) => _alertListeners.add(listener);
  void removeAlertListener(AlertCallback listener) => _alertListeners.remove(listener);

  void addIncidentListener(VoidCallback listener) => _incidentListeners.add(listener);
  void removeIncidentListener(VoidCallback listener) => _incidentListeners.remove(listener);

  void connect() {
    if (!kIsWeb || _isDisposed) return;

    try {
      final wsUrl = _buildWebSocketUrl();
      _socket = web.WebSocket(wsUrl);

      _socket?.onopen = (web.Event _) {
        // Enviar handshake STOMP
        _socket?.send(
          'CONNECT\naccept-version:1.2,1.1,1.0\nheart-beat:10000,10000\n\n\u0000',
        );
      };

      _socket?.onmessage = (web.MessageEvent event) {
        final rawData = event.data?.toString() ?? '';
        _handleStompMessage(rawData);
      };

      _socket?.onerror = (web.Event _) {
        _scheduleReconnect();
      };

      _socket?.onclose = (web.CloseEvent _) {
        _scheduleReconnect();
      };
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _handleStompMessage(String text) {
    if (text.startsWith('CONNECTED')) {
      // Suscribirse a tópicos de alertas e incidentes
      _socket?.send('SUBSCRIBE\nid:sub-0\ndestination:/topic/alerts\n\n\u0000');
      _socket?.send('SUBSCRIBE\nid:sub-1\ndestination:/topic/incidents\n\n\u0000');
      return;
    }

    if (text.startsWith('MESSAGE')) {
      final parts = text.split('\n\n');
      if (parts.length > 1) {
        final body = parts[1].replaceAll('\u0000', '').trim();
        if (body.isEmpty) return;

        try {
          final json = jsonDecode(body);
          if (json is Map<String, dynamic>) {
            // Notificar cambio de incidentes
            for (final listener in _incidentListeners) {
              listener();
            }

            // Si es alerta de emergencia
            if (json.containsKey('priority') &&
                (json['priority'] == 'CRITICAL' ||
                 json['type']?.toString().toUpperCase() == 'SOS' ||
                 json['type']?.toString().toUpperCase() == 'BOTON_PANICO')) {
              for (final listener in _alertListeners) {
                listener(json);
              }
            }
          }
        } catch (_) {}
      }
    }
  }

  String _buildWebSocketUrl() {
    var host = baseUrl;
    if (host.startsWith('https://')) {
      host = 'wss://${host.substring(8)}';
    } else if (host.startsWith('http://')) {
      host = 'ws://${host.substring(7)}';
    } else if (host.startsWith('/')) {
      final isSecure = web.window.location.protocol == 'https:';
      final currentHost = web.window.location.host;
      host = '${isSecure ? "wss" : "ws"}://$currentHost';
    }
    return '$host/ws';
  }

  void _scheduleReconnect() {
    if (_isDisposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 8), () {
      if (!_isDisposed) connect();
    });
  }

  void dispose() {
    _isDisposed = true;
    _reconnectTimer?.cancel();
    try {
      _socket?.close();
    } catch (_) {}
  }
}
