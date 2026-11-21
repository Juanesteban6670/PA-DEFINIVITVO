import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/data/location_service.dart';

// Matches the circular representation used by the district map.
const districtZoneRadiusMeters = 650.0;

double distanceToDistrictZone(double distanceToCenter) =>
    math.max(0, distanceToCenter - districtZoneRadiusMeters);

class ZoneProximityAlerts extends StatefulWidget {
  const ZoneProximityAlerts({super.key, required this.zones});

  final List<dynamic> zones;

  @override
  State<ZoneProximityAlerts> createState() => _ZoneProximityAlertsState();
}

class _ZoneProximityAlertsState extends State<ZoneProximityAlerts> {
  StreamSubscription<Position>? _positions;
  final _nearby = <String>{};
  int _threshold = 350;
  bool _starting = false;
  Position? _lastPosition;
  String? _message;

  Future<void> _toggle(bool enabled) async {
    if (!enabled) {
      await _positions?.cancel();
      _nearby.clear();
      _lastPosition = null;
      if (mounted) {
        setState(() {
          _positions = null;
          _message = null;
        });
      }
      return;
    }
    setState(() => _starting = true);
    try {
      final current = await LocationService.currentPosition();
      if (!mounted) return;
      _positions =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 25,
            ),
          ).listen(
            _evaluate,
            onError: (Object _) {
              if (mounted) {
                setState(
                  () => _message =
                      'Ubicación no disponible. Revisa el GPS y los permisos.',
                );
              }
            },
          );
      _evaluate(current);
    } on Exception catch (error) {
      if (mounted) {
        setState(
          () => _message = error is LocationAccessException ? error.message : 'No se pudo obtener la ubicación. Revisa el GPS y los permisos.',
        );
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  void didUpdateWidget(covariant ZoneProximityAlerts oldWidget) {
    super.didUpdateWidget(oldWidget);
    final position = _lastPosition;
    if (position != null && oldWidget.zones != widget.zones) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _positions != null) _evaluate(position);
      });
    }
  }

  void _evaluate(Position position) {
    if (!mounted) return;
    _lastPosition = position;
    if (!position.accuracy.isFinite ||
        position.accuracy <= 0 ||
        position.accuracy > math.min(100, _threshold / 2) ||
        DateTime.now().difference(position.timestamp).inSeconds > 90) {
      setState(() => _message = 'Esperando una ubicación reciente y precisa.');
      return;
    }
    final stillNearby = <String>{};
    (String, double)? nearestNew;
    for (final zone in widget.zones.whereType<Map<String, dynamic>>()) {
      if (zone['active'] == false ||
          !const {'HIGH', 'CRITICAL'}.contains(zone['riskLevel'])) {
        continue;
      }
      final id = zone['id'] as String?;
      final name = zone['name'] as String?;
      final lat = zone['centerLatitude'];
      final lng = zone['centerLongitude'];
      if (id == null || name == null || lat is! num || lng is! num) continue;
      final distance = distanceToDistrictZone(
        Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          lat.toDouble(),
          lng.toDouble(),
        ),
      );
      if (distance > _threshold + (_nearby.contains(id) ? 50 : 0)) continue;
      stillNearby.add(id);
      if (!_nearby.contains(id) &&
          (nearestNew == null || distance < nearestNew.$2)) {
        nearestNew = (name, distance);
      }
    }
    _nearby
      ..clear()
      ..addAll(stillNearby);
    if (_message != null) setState(() => _message = null);
    if (nearestNew case (final name, final distance)) {
      final label = distance == 0
          ? 'Estás dentro de la zona de riesgo $name.'
          : 'Zona de riesgo $name a unos ${distance.round()} m.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(label)));
    }
  }

  @override
  void dispose() {
    _positions?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile(
        title: const Text('Avisos de zonas de riesgo'),
        subtitle: Text(
          _message ?? 'Mientras usas la app · distancia aproximada',
        ),
        value: _positions != null,
        onChanged: _starting ? null : _toggle,
      ),
      if (_positions != null)
        DropdownButton<int>(
          value: _threshold,
          items: [
            for (final value in [150, 250, 350, 500, 750])
              DropdownMenuItem(value: value, child: Text('Avisar a $value m')),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() => _threshold = value);
            if (_lastPosition case final Position position) _evaluate(position);
          },
        ),
    ],
  );
}
