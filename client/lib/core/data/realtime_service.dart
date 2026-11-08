import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef AlertCallback = void Function(Map<String, dynamic> alert);

/// Servicio de sincronización y alertas en tiempo real resiliente y 100% multiplataforma.
/// Monitorea continuamente nuevos incidentes y activaciones de botón de pánico SOS.
class RealtimeAlertService {
  RealtimeAlertService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  final List<AlertCallback> _alertListeners = [];
  final List<VoidCallback> _incidentListeners = [];

  Timer? _pollingTimer;
  bool _isDisposed = false;
  final Set<String> _knownIds = {};
  bool _initialized = false;

  void addAlertListener(AlertCallback listener) => _alertListeners.add(listener);
  void removeAlertListener(AlertCallback listener) => _alertListeners.remove(listener);

  void addIncidentListener(VoidCallback listener) => _incidentListeners.add(listener);
  void removeIncidentListener(VoidCallback listener) => _incidentListeners.remove(listener);

  void connect() {
    if (_isDisposed) return;
    _checkNow();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkNow());
  }

  Future<void> _checkNow() async {
    if (_isDisposed) return;
    try {
      final url = _buildEndpoint('/api/Incidents');
      final response = await _client.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final list = (decoded is Map<String, dynamic> ? decoded['data'] : decoded) as List? ?? const [];

        bool hasNew = false;
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString() ?? '';
            if (id.isNotEmpty && !_knownIds.contains(id)) {
              if (_initialized) {
                hasNew = true;
                final priority = item['priority']?.toString().toUpperCase();
                final type = item['type']?.toString().toUpperCase();
                final isCritical = priority == 'CRITICAL' ||
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
    } catch (_) {
      // Ignorar fallas momentáneas de red para mantener resiliencia
    }
  }

  Uri _buildEndpoint(String path) {
    var base = baseUrl.trim();
    if (base.isEmpty || base == '/api') {
      return Uri.base.resolve(path);
    }
    if (base.endsWith('/')) {
      base = base.substring(0, base.length - 1);
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    if (base.startsWith('http://') || base.startsWith('https://')) {
      return Uri.parse('$base$cleanPath');
    }
    return Uri.base.resolve('$base$cleanPath');
  }

  void dispose() {
    _isDisposed = true;
    _pollingTimer?.cancel();
    _client.close();
  }
}
