import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/location_service.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/shared/notification_bridge.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Modelo de alerta de proximidad a una zona o sector con concentración de incidentes
class ProximityZoneAlert {
  const ProximityZoneAlert({
    required this.zoneName,
    required this.distanceMeters,
    required this.riskLevel,
    required this.incidentCount,
    required this.recentTypes,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  final String zoneName;
  final double distanceMeters;
  final String riskLevel; // 'ALTO', 'MEDIO', 'BAJO'
  final int incidentCount;
  final List<String> recentTypes;
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    }
    return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
  }
}

/// Servicio inteligente de detección de proximidad geográfica (Geofencing)
/// Monitorea la ubicación del usuario, evalúa el nivel de riesgo con datos reales de la BD,
/// y genera alertas preventivas sin duplicación excesiva.
class ProximityAlertService {
  ProximityAlertService._();
  static final ProximityAlertService instance = ProximityAlertService._();

  // Configuración y preferencias de usuario
  bool isAlertsEnabled = true;
  double alertRadiusMeters = 800.0;
  bool notifyMediumRisk = true;
  bool notifyHighRisk = true;

  // Registro de deduplicación: evita notificar la misma zona en un lapso de 30 minutos
  final Map<String, DateTime> _lastAlertsByZone = <String, DateTime>{};
  static const Duration _cooldownDuration = Duration(minutes: 30);

  Timer? _periodicCheckTimer;
  bool _isChecking = false;

  /// Inicia el chequeo periódico de proximidad (cada 60 segundos mientras la app está abierta)
  void startMonitoring({
    required ApiClient api,
    required void Function(ProximityZoneAlert alert) onAlertTriggered,
  }) {
    stopMonitoring();
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    // Ejecutar chequeo inicial diferido para no ralentizar el inicio
    Future.delayed(const Duration(seconds: 4), () {
      checkProximity(api: api, onAlertTriggered: onAlertTriggered);
    });

    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      checkProximity(api: api, onAlertTriggered: onAlertTriggered);
    });
  }

  void stopMonitoring() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  /// Evalúa la posición actual frente a incidentes y zonas activas de la base de datos
  Future<ProximityZoneAlert?> checkProximity({
    required ApiClient api,
    void Function(ProximityZoneAlert alert)? onAlertTriggered,
  }) async {
    if (!isAlertsEnabled || _isChecking) return null;

    _isChecking = true;
    try {
      // 1. Verificar permisos de ubicación de forma respetuosa
      final hasPerm = await LocationService.hasPermission();
      if (!hasPerm) return null;

      final Position position = await LocationService.currentPosition();

      // 2. Obtener incidentes reales de la base de datos
      final List<Incident> incidents = await loadIncidents(api, mine: false);

      // 3. Obtener zonas registradas de Cartagena
      final dynamic zonesRes = await api.get('Zones').catchError((_) => null);
      final List<dynamic> zonesList = zonesRes is List
          ? zonesRes
          : (zonesRes is Map && zonesRes['data'] is List
                ? zonesRes['data'] as List
                : []);

      // 4. Evaluar proximidad frente a zonas conocidas
      ProximityZoneAlert? highestAlert;

      for (final dynamic z in zonesList) {
        if (z is! Map<String, dynamic>) continue;
        final lat = (z['centerLatitude'] as num?)?.toDouble();
        final lon = (z['centerLongitude'] as num?)?.toDouble();
        final name = z['name']?.toString() ?? 'Zona de Cartagena';
        if (lat == null || lon == null) continue;

        final double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat,
          lon,
        );

        if (distance <= alertRadiusMeters) {
          // Filtrar incidentes cercanos a esta zona (< 600m del centro)
          final zoneIncidents = incidents.where((inc) {
            if (inc.latitude == null || inc.longitude == null) return false;
            final d = Geolocator.distanceBetween(
              lat,
              lon,
              inc.latitude!,
              inc.longitude!,
            );
            return d <= 600;
          }).toList();

          // Clasificación inteligente de nivel de riesgo
          final String riskLevel = _calculateRiskLevel(
            distance: distance,
            incidents: zoneIncidents,
            zoneRisk: z['riskLevel']?.toString(),
          );

          if ((riskLevel == 'ALTO' && notifyHighRisk) ||
              (riskLevel == 'MEDIO' && notifyMediumRisk)) {
            // Verificar deduplicación (cooldown de 30 min)
            final lastTime = _lastAlertsByZone[name];
            final now = DateTime.now();
            if (lastTime == null ||
                now.difference(lastTime) > _cooldownDuration) {
              final recentTypes = zoneIncidents
                  .map((i) => i.type)
                  .toSet()
                  .take(3)
                  .toList();

              final alert = ProximityZoneAlert(
                zoneName: name,
                distanceMeters: distance,
                riskLevel: riskLevel,
                incidentCount: zoneIncidents.length,
                recentTypes: recentTypes.isNotEmpty
                    ? recentTypes
                    : ['Atención preventiva'],
                latitude: lat,
                longitude: lon,
                timestamp: now,
              );

              if (highestAlert == null ||
                  _priorityScore(alert) > _priorityScore(highestAlert)) {
                highestAlert = alert;
              }
            }
          }
        }
      }

      // Si se encontró una alerta prioritaria, dispararla
      if (highestAlert != null) {
        _lastAlertsByZone[highestAlert.zoneName] = DateTime.now();

        // Notificación en navegador/push si está en segundo plano
        if (notificationPermissionGranted) {
          showBrowserNotification(
            '⚠️ Alerta de zona: ${highestAlert.zoneName}',
            'Estás a ${highestAlert.formattedDistance}. Nivel de riesgo ${highestAlert.riskLevel}. Incidentes: ${highestAlert.recentTypes.join(", ")}',
          );
        }

        if (onAlertTriggered != null) {
          onAlertTriggered(highestAlert);
        }
        return highestAlert;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProximityAlertService] Verificación de proximidad: $e');
      }
    } finally {
      _isChecking = false;
    }
    return null;
  }

  /// Calcula el nivel de riesgo combinando cantidad de incidentes, categoría, antigüedad y distancia
  String _calculateRiskLevel({
    required double distance,
    required List<Incident> incidents,
    String? zoneRisk,
  }) {
    if (zoneRisk?.toUpperCase() == 'CRITICAL' ||
        zoneRisk?.toUpperCase() == 'HIGH') {
      return 'ALTO';
    }

    int weightedScore = 0;
    final now = DateTime.now();

    for (final inc in incidents) {
      if (inc.status == 'RESOLVED') continue;

      int weight = 1;
      final type = inc.type.toUpperCase();

      // Ponderación por categoría
      if (type.contains('ROBO') ||
          type.contains('HURTO') ||
          type.contains('SOS') ||
          type.contains('PANICO')) {
        weight = 3;
      } else if (type.contains('SEGURIDAD') ||
          type.contains('ALTERCADO') ||
          type.contains('PELEA')) {
        weight = 2;
      }

      // Ponderación por antigüedad (más reciente = mayor peso)
      if (inc.createdAt != null) {
        final hoursAgo = now.difference(inc.createdAt!).inHours;
        if (hoursAgo <= 24) {
          weight *= 2;
        }
      }

      weightedScore += weight;
    }

    // Clasificación final
    if (weightedScore >= 5 || (weightedScore >= 3 && distance <= 350)) {
      return 'ALTO';
    } else if (weightedScore >= 2 || distance <= 500) {
      return 'MEDIO';
    }
    return 'BAJO';
  }

  int _priorityScore(ProximityZoneAlert a) {
    if (a.riskLevel == 'ALTO') return 3;
    if (a.riskLevel == 'MEDIO') return 2;
    return 1;
  }

  /// Diálogo interactivo para configurar preferencias de alertas geográficas
  void showPreferencesDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.brightBlue : AppColors.blue)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.fmd_good_rounded,
                      color: isDark ? AppColors.brightBlue : AppColors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Preferencias de Alertas GPS',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkText : AppColors.navy,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Alertas de proximidad activadas',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Notificarme si me aproximo a una zona de riesgo',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: isAlertsEnabled,
                    onChanged: (val) {
                      setStateDialog(() => isAlertsEnabled = val);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Radio de detección: ${alertRadiusMeters.round()} metros',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Slider.adaptive(
                    value: alertRadiusMeters,
                    min: 300,
                    max: 2000,
                    divisions: 17,
                    label: '${alertRadiusMeters.round()} m',
                    onChanged: isAlertsEnabled
                        ? (val) => setStateDialog(() => alertRadiusMeters = val)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  CheckboxListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Riesgo Alto y Emergencias',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: notifyHighRisk,
                    onChanged: isAlertsEnabled
                        ? (val) =>
                              setStateDialog(() => notifyHighRisk = val ?? true)
                        : null,
                  ),
                  CheckboxListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Riesgo Moderado y Tráfico',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: notifyMediumRisk,
                    onChanged: isAlertsEnabled
                        ? (val) => setStateDialog(
                            () => notifyMediumRisk = val ?? true,
                          )
                        : null,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.brightBlue
                        : AppColors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
