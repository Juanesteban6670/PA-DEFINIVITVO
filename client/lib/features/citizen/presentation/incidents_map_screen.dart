import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/incident_filters.dart';
import 'package:cartagena_segura/core/data/location_service.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/safe_route_service.dart';
import 'package:cartagena_segura/features/citizen/presentation/destination_search_dialog.dart';
import 'package:cartagena_segura/features/citizen/presentation/safe_route_sheet.dart';
import 'package:cartagena_segura/shared/location_guide_dialog.dart';
import 'package:cartagena_segura/shared/pill_badge.dart';
import 'package:cartagena_segura/shared/theme.dart';

enum MapTileTheme { auto, light, dark, satellite }

class IncidentsMapScreen extends StatefulWidget {
  const IncidentsMapScreen({
    required this.api,
    required this.incidentRefresh,
    super.key,
  });

  final ApiClient api;
  final ValueNotifier<int> incidentRefresh;

  @override
  State<IncidentsMapScreen> createState() => _IncidentsMapScreenState();
}

class _IncidentsMapScreenState extends State<IncidentsMapScreen> {
  final _mapController = MapController();
  late Future<List<Incident>> _incidents;
  Position? _position;
  bool _locating = false;
  String? _typeFilter;
  String? _statusFilter;
  String? _priorityFilter;
  double? _distanceFilterKm;
  String? _timeFilter;
  MapTileTheme _tileTheme = MapTileTheme.auto;

  List<SafeRoute>? _safeRoutes;
  int _selectedRouteIndex = 0;
  DestinationPreset? _selectedDestination;
  bool _isRouting = false;
  bool _isSelectingDestinationOnMap = false;

  List<_MapZone> _zones = const [];
  bool _showRiskZones = true;
  Incident? _selectedIncident;

  // --- MODO NAVEGACIÓN EN TIEMPO REAL (Estilo Waze) ---
  static const _distance = Distance();
  bool _isNavigating = false;
  bool _isFollowingGps = true;
  LatLng? _navPosition;
  double _navHeading = 0.0;
  double _currentSpeedKmh = 0.0;
  int _navRoutePointIndex = 0;
  double _navRemainingDistMeters = 0.0;
  double _navRemainingSecs = 0.0;
  String _navManeuverText = 'Continúa recto';
  IconData _navManeuverIcon = Icons.straight_rounded;
  double _navDistToNextManeuverMeters = 0.0;
  Incident? _approachingHazard;
  bool _hasArrived = false;
  bool _isSimulating = false;
  Timer? _simulationTimer;
  StreamSubscription<Position>? _gpsStreamSubscription;

  @override
  void initState() {
    super.initState();
    widget.incidentRefresh.addListener(_onIncidentRefresh);
    _incidents = _loadIncidents();
    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final res = await widget.api.get('Zones');
      if (res is Map<String, dynamic> && res['data'] is List) {
        final list = (res['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map(_MapZone.fromJson)
            .toList();
        if (mounted) setState(() => _zones = list);
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant IncidentsMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentRefresh != widget.incidentRefresh) {
      oldWidget.incidentRefresh.removeListener(_onIncidentRefresh);
      widget.incidentRefresh.addListener(_onIncidentRefresh);
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _gpsStreamSubscription?.cancel();
    widget.incidentRefresh.removeListener(_onIncidentRefresh);
    super.dispose();
  }

  void _onIncidentRefresh() => _reload();

  static List<Incident> _cachedIncidents = [];

  Future<List<Incident>> _loadIncidents() async {
    try {
      final response = await widget.api.get('Incidents');
      if (response is! List) {
        throw const FormatException(
          'La API devolvió una lista de incidentes inválida',
        );
      }
      final list = response
          .whereType<Map<String, dynamic>>()
          .map(Incident.fromJson)
          .toList();
      _cachedIncidents = list;
      return list;
    } catch (_) {
      if (_cachedIncidents.isNotEmpty) {
        return _cachedIncidents;
      }
      rethrow;
    }
  }

  void _reload() {
    setState(() {
      _incidents = _loadIncidents();
    });
  }

  Future<void> _locateMe() async {
    if (kIsWeb) {
      final hasPerm = await LocationService.hasPermission();
      final isBlocked = await LocationService.isPermissionBlocked();
      if (!hasPerm && !isBlocked) {
        if (!mounted) return;
        final accepted = await showLocationPrimingDialog(context);
        if (!accepted) return;
      }
    }

    setState(() => _locating = true);
    try {
      final position = await LocationService.currentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } on LocationAccessException catch (error) {
      if (error.isPermissionBlocked ||
          (kIsWeb && error.settingsTarget != null)) {
        if (!mounted) return;
        await showLocationBlockedDialog(context);
      } else {
        _showLocationError(error);
      }
    } on Exception catch (error) {
      _showMessage(
        'No se pudo determinar tu ubicación. Revisa la señal GPS e inténtalo de nuevo: $error',
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showLocationError(LocationAccessException error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.message),
        duration: const Duration(seconds: 8),
        action: error.settingsTarget == null
            ? null
            : SnackBarAction(
                label: kIsWeb ? 'Ver ayuda' : 'Abrir ajustes',
                onPressed: () async {
                  if (kIsWeb) {
                    await showLocationBlockedDialog(context);
                  } else {
                    final opened = await LocationService.openSettings(
                      error.settingsTarget!,
                    );
                    if (!opened && mounted) {
                      _showMessage(
                        'No fue posible abrir los ajustes del sistema.',
                      );
                    }
                  }
                },
              ),
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openDestinationSearch() async {
    final start = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : null;

    final result = await showDialog<dynamic>(
      context: context,
      builder: (context) => DestinationSearchDialog(currentLocation: start),
    );

    if (!mounted || result == null) return;

    if (result == 'CHOOSE_ON_MAP') {
      setState(() => _isSelectingDestinationOnMap = true);
      _showMessage('Toca cualquier punto del mapa para fijar tu destino');
      return;
    }

    if (result is DestinationPreset) {
      await _startRouting(result);
    }
  }

  void _onMapTap(LatLng point) {
    if (_isSelectingDestinationOnMap) {
      setState(() => _isSelectingDestinationOnMap = false);
      final dest = DestinationPreset(
        name: 'Punto fijado en el mapa',
        description:
            '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
        location: point,
        category: 'Personalizado',
      );
      _startRouting(dest);
    }
  }

  Future<void> _startRouting(DestinationPreset destination) async {
    setState(() {
      _isRouting = true;
      _selectedDestination = destination;
    });

    LatLng origin;
    if (_position != null) {
      origin = LatLng(_position!.latitude, _position!.longitude);
    } else {
      try {
        final pos = await LocationService.currentPosition();
        if (mounted) setState(() => _position = pos);
        origin = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        origin = const LatLng(10.4236, -75.5478);
      }
    }

    try {
      final currentIncidents = await _incidents;
      final routes = await SafeRouteService.calculateRoutes(
        origin: origin,
        destination: destination.location,
        incidents: currentIncidents,
      );

      if (!mounted) return;
      setState(() {
        _safeRoutes = routes;
        _selectedRouteIndex = 0;
      });

      _centerRoute();
    } catch (e) {
      if (mounted) {
        _showMessage('No fue posible calcular las rutas seguras: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRouting = false);
      }
    }
  }

  void _centerRoute() {
    if (_safeRoutes == null || _safeRoutes!.isEmpty) return;
    final active = _safeRoutes![_selectedRouteIndex];
    if (active.points.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(active.points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(40, 90, 40, 220),
      ),
    );
  }

  void _startNavigation() {
    if (_safeRoutes == null || _safeRoutes!.isEmpty) return;
    final activeRoute = _safeRoutes![_selectedRouteIndex];
    if (activeRoute.points.isEmpty) return;

    final startPoint = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : activeRoute.points.first;

    setState(() {
      _isNavigating = true;
      _isFollowingGps = true;
      _hasArrived = false;
      _navPosition = startPoint;
      _navRoutePointIndex = 0;
      _navRemainingDistMeters = activeRoute.distanceMeters;
      _navRemainingSecs = activeRoute.durationSeconds;
      _currentSpeedKmh = 0.0;
      _navHeading = 0.0;
    });

    _mapController.move(startPoint, 17.5);
    _updateNavProgress(startPoint, activeRoute);
    _startGpsStream(activeRoute);
  }

  void _stopNavigation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _gpsStreamSubscription?.cancel();
    _gpsStreamSubscription = null;
    setState(() {
      _isNavigating = false;
      _isSimulating = false;
      _approachingHazard = null;
      _hasArrived = false;
      _currentSpeedKmh = 0.0;
    });
    _centerRoute();
  }

  void _startGpsStream(SafeRoute route) {
    _gpsStreamSubscription?.cancel();
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 2,
    );
    try {
      _gpsStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (pos) {
          if (!_isNavigating || !mounted) return;
          if (_isSimulating) return;

          final newPoint = LatLng(pos.latitude, pos.longitude);
          final speed = pos.speed > 0 ? (pos.speed * 3.6) : 0.0;
          final heading = pos.heading > 0 ? pos.heading : _navHeading;

          setState(() {
            _position = pos;
            _navPosition = newPoint;
            _currentSpeedKmh = speed;
            if (pos.heading > 0) _navHeading = heading;
          });

          _updateNavProgress(newPoint, route);

          if (_isFollowingGps) {
            _mapController.move(newPoint, 17.5);
          }
        },
        onError: (err) {
          debugPrint('Error en stream GPS de navegación: $err');
        },
      );
    } catch (e) {
      debugPrint('No se pudo inicializar getPositionStream: $e');
    }
  }

  void _updateNavProgress(LatLng currentLoc, SafeRoute route) {
    if (route.points.isEmpty) return;

    // 1. Encontrar el punto más cercano en la polilínea
    var closestIdx = _navRoutePointIndex;
    var minDistance = double.infinity;
    final searchStart = max(0, _navRoutePointIndex - 2);
    final searchEnd = min(route.points.length, _navRoutePointIndex + 25);

    for (var i = searchStart; i < searchEnd; i++) {
      final d = _distance.as(LengthUnit.Meter, currentLoc, route.points[i]);
      if (d < minDistance) {
        minDistance = d;
        closestIdx = i;
      }
    }
    _navRoutePointIndex = max(_navRoutePointIndex, closestIdx);

    // 2. Calcular distancia restante sumando segmentos futuros
    var remainingDist = _distance.as(
      LengthUnit.Meter,
      currentLoc,
      route.points[_navRoutePointIndex],
    );
    for (var i = _navRoutePointIndex; i < route.points.length - 1; i++) {
      remainingDist += _distance.as(
        LengthUnit.Meter,
        route.points[i],
        route.points[i + 1],
      );
    }

    final remainingSecs = (route.distanceMeters > 0)
        ? (remainingDist / route.distanceMeters) * route.durationSeconds
        : 0.0;

    // 3. Comprobar si ha llegado a destino (< 25 metros o último punto)
    if (remainingDist < 25 || _navRoutePointIndex >= route.points.length - 1) {
      setState(() {
        _hasArrived = true;
        _isSimulating = false;
        _currentSpeedKmh = 0.0;
        _navRemainingDistMeters = 0.0;
        _navRemainingSecs = 0.0;
        _navManeuverText = '¡Llegaste a tu destino!';
        _navManeuverIcon = Icons.flag_rounded;
        _navDistToNextManeuverMeters = 0.0;
        _approachingHazard = null;
      });
      _simulationTimer?.cancel();
      return;
    }

    // 4. Calcular próximo giro/maniobra analizando cambios de ángulo en los vértices
    IconData maneuverIcon = Icons.straight_rounded;
    String maneuverText = 'Continúa recto por la vía';
    double distToTurn = remainingDist;

    var accumulatedDist = _distance.as(
      LengthUnit.Meter,
      currentLoc,
      route.points[_navRoutePointIndex],
    );

    for (var i = _navRoutePointIndex; i < route.points.length - 2; i++) {
      final pA = route.points[i];
      final pB = route.points[i + 1];
      final pC = route.points[i + 2];

      final bearing1 = _distance.bearing(pA, pB);
      final bearing2 = _distance.bearing(pB, pC);
      final angleDiff = (bearing2 - bearing1 + 540) % 360 - 180;

      accumulatedDist += _distance.as(LengthUnit.Meter, pA, pB);

      if (angleDiff.abs() >= 25.0) {
        distToTurn = accumulatedDist;
        if (angleDiff > 25.0) {
          if (angleDiff > 70.0) {
            maneuverIcon = Icons.turn_right_rounded;
            maneuverText = distToTurn < 30
                ? 'Gira ahora a la derecha'
                : 'En ${_formatManeuverDist(distToTurn)} gira a la derecha';
          } else {
            maneuverIcon = Icons.turn_slight_right_rounded;
            maneuverText = distToTurn < 30
                ? 'Curva a la derecha'
                : 'En ${_formatManeuverDist(distToTurn)} curva a la derecha';
          }
        } else {
          if (angleDiff < -70.0) {
            maneuverIcon = Icons.turn_left_rounded;
            maneuverText = distToTurn < 30
                ? 'Gira ahora a la izquierda'
                : 'En ${_formatManeuverDist(distToTurn)} gira a la izquierda';
          } else {
            maneuverIcon = Icons.turn_slight_left_rounded;
            maneuverText = distToTurn < 30
                ? 'Curva a la izquierda'
                : 'En ${_formatManeuverDist(distToTurn)} curva a la izquierda';
          }
        }
        break;
      }

      if (accumulatedDist > 700) {
        maneuverIcon = Icons.straight_rounded;
        maneuverText = 'Continúa recto por la ruta recomendada';
        distToTurn = accumulatedDist;
        break;
      }
    }

    // 5. Cálculo de orientación/rumbo (bearing) si la velocidad o GPS no la reporta
    if (_navRoutePointIndex < route.points.length - 1) {
      final nextP = route.points[_navRoutePointIndex + 1];
      final b = _distance.bearing(currentLoc, nextP);
      if (!_isSimulating && _position?.heading != null && _position!.heading > 0) {
        _navHeading = _position!.heading;
      } else {
        _navHeading = (b + 360) % 360;
      }
    }

    // 6. Detección de incidentes/peligros cercanos en la ruta (< 350 metros)
    Incident? approaching;
    for (final hazard in route.hazardsOnRoute) {
      if (hazard.latitude == null || hazard.longitude == null) continue;
      final hLoc = LatLng(hazard.latitude!, hazard.longitude!);
      final hDist = _distance.as(LengthUnit.Meter, currentLoc, hLoc);
      if (hDist <= 350.0) {
        approaching = hazard;
        break;
      }
    }

    setState(() {
      _navRemainingDistMeters = remainingDist;
      _navRemainingSecs = remainingSecs;
      _navManeuverIcon = maneuverIcon;
      _navManeuverText = maneuverText;
      _navDistToNextManeuverMeters = distToTurn;
      _approachingHazard = approaching;
    });
  }

  void _toggleSimulation() {
    if (_safeRoutes == null || _safeRoutes!.isEmpty) return;
    final activeRoute = _safeRoutes![_selectedRouteIndex];
    if (activeRoute.points.isEmpty) return;

    if (_isSimulating) {
      _simulationTimer?.cancel();
      _simulationTimer = null;
      setState(() {
        _isSimulating = false;
        _currentSpeedKmh = 0.0;
      });
      return;
    }

    setState(() {
      _isSimulating = true;
      _isFollowingGps = true;
      if (_hasArrived || _navRoutePointIndex >= activeRoute.points.length - 2) {
        _navRoutePointIndex = 0;
        _hasArrived = false;
      }
    });

    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (!_isNavigating || !_isSimulating || !mounted) {
        timer.cancel();
        return;
      }

      if (_navRoutePointIndex < activeRoute.points.length - 1) {
        _navRoutePointIndex++;
        final cur = activeRoute.points[_navRoutePointIndex];
        final simSpeed = 36.0 + (Random().nextDouble() * 14.0);

        setState(() {
          _navPosition = cur;
          _currentSpeedKmh = simSpeed;
        });

        _updateNavProgress(cur, activeRoute);

        if (_isFollowingGps) {
          _mapController.move(cur, 17.5);
        }
      } else {
        timer.cancel();
        setState(() {
          _isSimulating = false;
          _hasArrived = true;
          _currentSpeedKmh = 0.0;
        });
      }
    });
  }

  void _recenterNavigation() {
    if (_navPosition != null) {
      setState(() => _isFollowingGps = true);
      _mapController.move(_navPosition!, 17.5);
    }
  }

  String _formatManeuverDist(double meters) {
    if (meters < 20) return 'ahora';
    if (meters < 1000) return '${(meters / 10).round() * 10} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatNavEta(double seconds) {
    final now = DateTime.now();
    final arrival = now.add(Duration(seconds: seconds.round()));
    final hour = arrival.hour > 12
        ? arrival.hour - 12
        : (arrival.hour == 0 ? 12 : arrival.hour);
    final min = arrival.minute.toString().padLeft(2, '0');
    final period = arrival.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $period';
  }

  String _formatNavDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainingMin = minutes % 60;
    return '${hours}h ${remainingMin}m';
  }

  void _closeRoute() {
    _stopNavigation();
    setState(() {
      _safeRoutes = null;
      _selectedDestination = null;
      _selectedRouteIndex = 0;
      _isRouting = false;
    });
  }

  Color _routeColor(SafetyLevel level) => switch (level) {
        SafetyLevel.safe => const Color(0xFF10B981),
        SafetyLevel.moderate => const Color(0xFFF59E0B),
        SafetyLevel.risky => const Color(0xFFEF4444),
      };

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  void _cycleTileTheme() {
    setState(() {
      _tileTheme = switch (_tileTheme) {
        MapTileTheme.auto => MapTileTheme.light,
        MapTileTheme.light => MapTileTheme.dark,
        MapTileTheme.dark => MapTileTheme.satellite,
        MapTileTheme.satellite => MapTileTheme.auto,
      };
    });
    final label = switch (_tileTheme) {
      MapTileTheme.auto => 'Estilo de mapa: Automático (sigue el tema)',
      MapTileTheme.light => 'Estilo de mapa: Claro (OpenStreetMap estándar)',
      MapTileTheme.dark => 'Estilo de mapa: Modo Oscuro (Cyber)',
      MapTileTheme.satellite => 'Estilo de mapa: Vista Satelital (Esri)',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isDarkMap = switch (_tileTheme) {
      MapTileTheme.auto => isDark,
      MapTileTheme.dark => true,
      MapTileTheme.light => false,
      MapTileTheme.satellite => false,
    };
    final isSatellite = _tileTheme == MapTileTheme.satellite;
    final urlTemplate = isSatellite
        ? 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return FutureBuilder<List<Incident>>(
      future: _incidents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _LoadError(
            message: snapshot.error.toString(),
            onRetry: _reload,
          );
        }

        final incidents = snapshot.data ?? const <Incident>[];
        var filtered = filterIncidents(
          incidents,
          type: _typeFilter,
          status: _statusFilter,
          priority: _priorityFilter,
        );

        if (_timeFilter != null) {
          final now = DateTime.now();
          final maxHours = switch (_timeFilter) {
            '24H' => 24,
            '72H' => 72,
            'WEEK' => 24 * 7,
            'MONTH' => 24 * 30,
            _ => 24 * 365,
          };
          filtered = filtered.where((inc) {
            if (inc.createdAt == null) return true;
            return now.difference(inc.createdAt!).inHours <= maxHours;
          }).toList();
        }

        if (_distanceFilterKm != null && _position != null) {
          const distCalc = Distance();
          final userPt = LatLng(_position!.latitude, _position!.longitude);
          filtered = filtered.where((inc) {
            if (inc.latitude == null || inc.longitude == null) return false;
            final incPt = LatLng(inc.latitude!, inc.longitude!);
            final km = distCalc.as(LengthUnit.Kilometer, userPt, incPt);
            return km <= _distanceFilterKm!;
          }).toList();
        }
        final withLocation = filtered
            .where(
              (incident) =>
                  incident.latitude != null && incident.longitude != null,
            )
            .toList();
        final withoutLocation = filtered
            .where(
              (incident) =>
                  incident.latitude == null || incident.longitude == null,
            )
            .toList();

        final displayedIncident = _selectedIncident ??
            (withLocation.isNotEmpty ? withLocation.first : null);

        return Scaffold(
          backgroundColor: isDark ? AppColors.darkCanvas : const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                // Encabezado Figma (03 · Mapa) - Oculto durante navegación activa para pantalla completa tipo Waze
                if (!_isNavigating)
                  Container(
                    color: isDark ? AppColors.darkSurface : const Color(0xFFF8FAFC),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mapa de tu ciudad',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Muévete informado. Llega seguro.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _openDestinationSearch,
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  height: 44,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCard : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.search_rounded,
                                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Buscar sector o dirección',
                                          style: TextStyle(
                                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                                            fontSize: 13,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => _showFilters(context),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Badge(
                                  isLabelVisible: _typeFilter != null ||
                                      _statusFilter != null ||
                                      _priorityFilter != null ||
                                      _distanceFilterKm != null ||
                                      _timeFilter != null,
                                  child: Icon(
                                    Icons.tune_rounded,
                                    color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Mapa y Controles Flotantes
                Expanded(
                  child: Stack(
                    children: [
                      // Mapa a pantalla completa
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(10.391, -75.4794),
                          initialZoom: 12.5,
                          onTap: (tapPosition, point) => _onMapTap(point),
                          onPositionChanged: (camera, hasGesture) {
                            if (hasGesture && _isNavigating && _isFollowingGps) {
                              setState(() => _isFollowingGps = false);
                            }
                          },
                        ),
                        children: [
                          if (isDarkMap)
                            darkModeTilesContainerBuilder(
                              context,
                              TileLayer(
                                urlTemplate: urlTemplate,
                                panBuffer: 2,
                                evictErrorTileStrategy: EvictErrorTileStrategy.none,
                                userAgentPackageName:
                                    'com.cartagenasegura.cartagena_segura',
                              ),
                            )
                          else
                            TileLayer(
                              urlTemplate: urlTemplate,
                              panBuffer: 2,
                              evictErrorTileStrategy: EvictErrorTileStrategy.none,
                              userAgentPackageName:
                                  'com.cartagenasegura.cartagena_segura',
                            ),

                // Capa de Zonas de Riesgo Distrital
                if (_showRiskZones && _zones.isNotEmpty)
                  CircleLayer(
                    circles: [
                      for (final zone in _zones)
                        CircleMarker(
                          point: zone.center,
                          radius: 650,
                          useRadiusInMeter: true,
                          color: _zoneColor(zone.riskLevel)
                              .withValues(alpha: isDark ? 0.16 : 0.12),
                          borderColor: _zoneColor(zone.riskLevel)
                              .withValues(alpha: isDark ? 0.55 : 0.45),
                          borderStrokeWidth: 1.5,
                        ),
                    ],
                  ),

                // Capa de Rutas Seguras (PolylineLayer)
                if (_safeRoutes case final routes? when routes.isNotEmpty) ...[
                  PolylineLayer(
                    polylines: [
                      for (var i = 0; i < routes.length; i++)
                        if (i != _selectedRouteIndex)
                          Polyline(
                            points: routes[i].points,
                            strokeWidth: 4.0,
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFF94A3B8),
                            borderColor:
                                isDark ? Colors.black54 : Colors.white70,
                            borderStrokeWidth: 1.0,
                          ),
                      Polyline(
                        points: routes[_selectedRouteIndex].points,
                        strokeWidth: 6.0,
                        color: _routeColor(
                          routes[_selectedRouteIndex].safetyLevel,
                        ),
                        borderColor: isDark ? Colors.black : Colors.white,
                        borderStrokeWidth: 2.5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Marcador de inicio (Origen)
                      Marker(
                        point: routes[_selectedRouteIndex].points.first,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.brightBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brightBlue.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.near_me_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      // Marcador de destino
                      Marker(
                        point: routes[_selectedRouteIndex].points.last,
                        width: 40,
                        height: 40,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.red.withValues(alpha: 0.4),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      // Peligros detectados en la ruta
                      for (final hazard
                          in routes[_selectedRouteIndex].hazardsOnRoute)
                        Marker(
                          point: LatLng(hazard.latitude!, hazard.longitude!),
                          width: 32,
                          height: 32,
                          child: Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF450A0A)
                                  : const Color(0xFFFEF2F2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.red,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.red,
                              size: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],

                // Marcadores de incidentes reportados (con clustering en zooms lejanos)
                MarkerLayer(
                  markers: [
                    ..._buildIncidentMarkers(withLocation, isDark),
                    // Marcador GPS: Cursor de navegación direccional Waze o marcador estándar
                    if (_isNavigating && _navPosition != null)
                      Marker(
                        point: _navPosition!,
                        width: 56,
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3B82F6)
                                    .withValues(alpha: 0.22),
                              ),
                            ),
                            Transform.rotate(
                              angle: (_navHeading * pi) / 180,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF0F4C81),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F4C81)
                                          .withValues(alpha: 0.45),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.navigation_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_position case final position?)
                      Marker(
                        point: LatLng(position.latitude, position.longitude),
                        width: 48,
                        height: 48,
                        child: const _ModernUserLocationMarker(),
                      ),
                  ],
                ),

                RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      isSatellite
                          ? 'Esri, Maxar, Earthstar Geographics'
                          : 'OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),

            // Badge flotante "En tiempo real" (Figma 03 · Mapa) - Oculto durante navegación
            if (!_isNavigating)
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'En tiempo real',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Acciones rápidas superiores derechas (Lista accesible + Actualizar) - Oculto durante navegación
            if (!_isNavigating)
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Ver lista accesible de incidentes',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showIncidentList(filtered),
                        icon: Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 18,
                          color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Actualizar incidentes',
                        visualDensity: VisualDensity.compact,
                        onPressed: _reload,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 18,
                          color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Botón flotante para Trazar Ruta Segura estilo Waze
            if (!_isSelectingDestinationOnMap && _safeRoutes == null)
              Positioned(
                top: 54,
                left: 14,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1D4ED8).withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _openDestinationSearch,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.alt_route_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Trazar Ruta Segura',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Banner informativo para elegir destino en el mapa
            if (_isSelectingDestinationOnMap)
              Positioned(
                top: 76,
                left: 14,
                right: 14,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: isDark ? AppColors.darkCard : AppColors.navy,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.touch_app_rounded,
                          color: Color(0xFFFBBF24),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Toca en el mapa el punto de destino',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onPressed: () => setState(
                            () => _isSelectingDestinationOnMap = false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Indicador de cálculo de rutas
            if (_isRouting)
              Positioned(
                top: 130,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Calculando rutas seguras en Cartagena…',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkText : AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Barra lateral flotante de controles (Zoom + Zonas + Mi Ubicación)
            Positioned(
              right: 14,
              bottom: _isNavigating ? 190 : (_safeRoutes != null ? 240 : 190),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FloatingMapButton(
                    tooltip: 'Cambiar estilo de mapa',
                    icon: switch (_tileTheme) {
                      MapTileTheme.auto => Icons.layers_outlined,
                      MapTileTheme.light => Icons.wb_sunny_outlined,
                      MapTileTheme.dark => Icons.nightlight_round,
                      MapTileTheme.satellite => Icons.satellite_alt_outlined,
                    },
                    isDark: isDark,
                    onPressed: _cycleTileTheme,
                  ),
                  const SizedBox(height: 8),
                  _FloatingMapButton(
                    tooltip: _showRiskZones
                        ? 'Ocultar sectores distritales'
                        : 'Ver sectores de seguridad',
                    icon: _showRiskZones
                        ? Icons.security_rounded
                        : Icons.security_outlined,
                    isDark: isDark,
                    isActive: _showRiskZones,
                    onPressed: () =>
                        setState(() => _showRiskZones = !_showRiskZones),
                  ),
                  const SizedBox(height: 8),
                  _FloatingMapButton(
                    tooltip: 'Acercar',
                    icon: Icons.add_rounded,
                    isDark: isDark,
                    onPressed: _zoomIn,
                  ),
                  const SizedBox(height: 8),
                  _FloatingMapButton(
                    tooltip: 'Alejar',
                    icon: Icons.remove_rounded,
                    isDark: isDark,
                    onPressed: _zoomOut,
                  ),
                  const SizedBox(height: 12),
                  // Botón Mi Ubicación
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F4C81).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FloatingActionButton.small(
                      heroTag: 'locate_me_fab',
                      tooltip: 'Mi ubicación GPS',
                      backgroundColor: const Color(0xFF0F4C81),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      onPressed: _locating ? null : _locateMe,
                      child: _locating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Tarjeta flotante inferior: Incidente cercano (Figma 03 · Mapa)
            if (_safeRoutes == null && !_isNavigating)
              Positioned(
                bottom: 14,
                left: 16,
                right: 16,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _FigmaMapIncidentCard(
                      incident: displayedIncident,
                      onTapReport: () {
                        if (displayedIncident != null) {
                          _showIncident(displayedIncident);
                        }
                      },
                    ),
                  ),
                ),
              ),

            // Tarjeta HUD de la Ruta Segura activa (Estilo Waze) o HUD de Navegación Activa
            if (_safeRoutes case final routes? when routes.isNotEmpty) ...[
              if (_isNavigating) ...[
                _buildTopManeuverCard(isDark),
                _buildHazardAlertBanner(isDark),
                _buildSpeedometer(isDark),
                _buildRecenterButton(isDark),
                _buildBottomNavHud(routes[_selectedRouteIndex], isDark),
                _buildArrivalCelebration(isDark),
              ] else
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SafeRouteSheet(
                      routes: routes,
                      selectedRouteIndex: _selectedRouteIndex,
                      destinationName:
                          _selectedDestination?.name ?? 'Destino seleccionado',
                      onSelectRoute: (idx) {
                        setState(() => _selectedRouteIndex = idx);
                        _centerRoute();
                      },
                      onCloseRoute: _closeRoute,
                      onCenterRoute: _centerRoute,
                      onStartNavigation: _startNavigation,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ],
  ),
),
);
},
);
}

  Widget _buildTopManeuverCard(bool isDark) {
    return Positioned(
      top: 14,
      left: 14,
      right: 14,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(18),
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F4C81), Color(0xFF1E3A8A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F4C81).withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _hasArrived
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                    child: Icon(
                      _navManeuverIcon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_hasArrived)
                          Text(
                            _navDistToNextManeuverMeters < 30
                                ? 'Ahora'
                                : 'En ${_formatManeuverDist(_navDistToNextManeuverMeters)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        Text(
                          _navManeuverText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Detener navegación',
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: _stopNavigation,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHazardAlertBanner(bool isDark) {
    if (_approachingHazard == null) return const SizedBox.shrink();
    final hazard = _approachingHazard!;
    final hazardDist = (_navPosition != null &&
            hazard.latitude != null &&
            hazard.longitude != null)
        ? _distance
            .as(
              LengthUnit.Meter,
              _navPosition!,
              LatLng(hazard.latitude!, hazard.longitude!),
            )
            .round()
        : 200;

    return Positioned(
      top: 96,
      left: 14,
      right: 14,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFFB91C1C),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFB91C1C).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '¡ALERTA DE PELIGRO EN TU RUTA!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'A $hazardDist m: ${hazard.type} • ${hazard.description.isNotEmpty ? hazard.description : hazard.location}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                    onPressed: () => setState(() => _approachingHazard = null),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedometer(bool isDark) {
    return Positioned(
      bottom: 120,
      left: 16,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF0F4C81),
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_currentSpeedKmh.round()}',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F4C81),
                height: 1.0,
              ),
            ),
            Text(
              'km/h',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecenterButton(bool isDark) {
    if (_isFollowingGps) return const SizedBox.shrink();
    return Positioned(
      bottom: 120,
      right: 16,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F4C81),
          foregroundColor: Colors.white,
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: _recenterNavigation,
        icon: const Icon(Icons.navigation_rounded, size: 18),
        label: const Text(
          'Recentrar',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildBottomNavHud(SafeRoute route, bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Fila 1: Indicadores clave (Tiempo restante, Distancia, Hora estimada)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatNavDuration(_navRemainingSecs),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F4C81),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '${(_navRemainingDistMeters / 1000).toStringAsFixed(1)} km restantes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              size: 15,
                              color: Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatNavEta(_navRemainingSecs),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFA7F3D0),
                            ),
                          ),
                          child: Text(
                            '${route.safetyScore}% SEGURO',
                            style: const TextStyle(
                              color: Color(0xFF047857),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.border,
                ),
                const SizedBox(height: 10),
                // Fila 2: Botones de control (Simular recorrido / Detener)
                Row(
                  children: [
                    // Botón Simular recorrido (ideal para pruebas en PC/laptop)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleSimulation,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isSimulating
                              ? const Color(0xFFD97706)
                              : const Color(0xFF0F4C81),
                          side: BorderSide(
                            color: _isSimulating
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: Icon(
                          _isSimulating
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                        label: Text(
                          _isSimulating ? 'Pausar simulación' : 'Simular recorrido',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Botón Salir / Detener navegación
                    ElevatedButton.icon(
                      onPressed: _stopNavigation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: const Text(
                        'Salir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArrivalCelebration(bool isDark) {
    if (!_hasArrived) return const SizedBox.shrink();
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Material(
            elevation: 12,
            borderRadius: BorderRadius.circular(20),
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981),
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: Color(0xFF059669),
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¡Llegaste a tu destino!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F4C81),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Has completado la ruta con seguridad en Cartagena Segura.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextMuted
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _stopNavigation,
                      child: const Text(
                        'Finalizar navegación',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    var type = _typeFilter;
    var status = _statusFilter;
    var priority = _priorityFilter;
    var distance = _distanceFilterKm;
    var time = _timeFilter;

    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Filtros Avanzados del Mapa',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 14),
                  _filterDropdown(
                    label: 'Tipo de Incidente',
                    value: type,
                    values: const [
                      'ROBO',
                      'ACCIDENTE',
                      'PELEA',
                      'INCENDIO',
                      'EMERGENCIA',
                      'ACTIVIDAD_SOSPECHOSA',
                      'LUMINARIA_DANADA',
                      'OBSTACULO_VIAL',
                      'OTRO',
                    ],
                    onChanged: (value) => update(() => type = value),
                  ),
                  const SizedBox(height: 10),
                  _filterDropdown(
                    label: 'Estado Operativo',
                    value: status,
                    values: const [
                      'PENDING',
                      'IN_PROGRESS',
                      'RESOLVED',
                      'REJECTED',
                    ],
                    onChanged: (value) => update(() => status = value),
                  ),
                  const SizedBox(height: 10),
                  _filterDropdown(
                    label: 'Prioridad',
                    value: priority,
                    values: const ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
                    onChanged: (value) => update(() => priority = value),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<double>(
                    initialValue: distance,
                    decoration: const InputDecoration(
                      labelText: 'Radio de Proximidad GPS',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Cualquier distancia'),
                      ),
                      DropdownMenuItem(
                        value: 1.0,
                        child: Text('A menos de 1 km'),
                      ),
                      DropdownMenuItem(
                        value: 3.0,
                        child: Text('A menos de 3 km'),
                      ),
                      DropdownMenuItem(
                        value: 5.0,
                        child: Text('A menos de 5 km'),
                      ),
                      DropdownMenuItem(
                        value: 10.0,
                        child: Text('A menos de 10 km'),
                      ),
                    ],
                    onChanged: (val) => update(() => distance = val),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: time,
                    decoration: const InputDecoration(
                      labelText: 'Antigüedad / Período',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Todo el histórico'),
                      ),
                      DropdownMenuItem(
                        value: '24H',
                        child: Text('Últimas 24 horas'),
                      ),
                      DropdownMenuItem(
                        value: '72H',
                        child: Text('Últimos 3 días'),
                      ),
                      DropdownMenuItem(
                        value: 'WEEK',
                        child: Text('Última semana'),
                      ),
                      DropdownMenuItem(
                        value: 'MONTH',
                        child: Text('Último mes'),
                      ),
                    ],
                    onChanged: (val) => update(() => time = val),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        onPressed: () {
                          update(() {
                            type = null;
                            status = null;
                            priority = null;
                            distance = null;
                            time = null;
                          });
                        },
                        label: const Text('Limpiar todos'),
                      ),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Aplicar filtros'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (applied == true && mounted) {
      setState(() {
        _typeFilter = type;
        _statusFilter = status;
        _priorityFilter = priority;
        _distanceFilterKm = distance;
        _timeFilter = time;
      });
    }
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: [
          const DropdownMenuItem<String>(value: null, child: Text('Todos')),
          ...values.map(
            (item) => DropdownMenuItem(value: item, child: Text(_label(item))),
          ),
        ],
        onChanged: onChanged,
      );

  String _label(String value) => switch (value) {
        'ROBO' => 'Robo',
        'ACCIDENTE' => 'Accidente',
        'PELEA' => 'Pelea',
        'INCENDIO' => 'Incendio',
        'EMERGENCIA' => 'Emergencia',
        'ACTIVIDAD_SOSPECHOSA' => 'Actividad Sospechosa',
        'LUMINARIA_DANADA' => 'Alumbrado Público',
        'OBSTACULO_VIAL' => 'Obstáculo Vial',
        'OTRO' => 'Otro',
        'PENDING' => 'Pendiente',
        'IN_PROGRESS' => 'En progreso',
        'RESOLVED' => 'Resuelto',
        'REJECTED' => 'Rechazado',
        'LOW' => 'Baja',
        'MEDIUM' => 'Media',
        'HIGH' => 'Alta',
        'CRITICAL' => 'Crítica',
        _ => value,
      };

  void _showIncidentList(List<Incident> incidents) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: incidents.isEmpty
              ? const Center(
                  child: Text('No hay incidentes con estos filtros.'),
                )
              : ListView.builder(
                  itemCount: incidents.length,
                  itemBuilder: (context, index) {
                    final incident = incidents[index];
                    return ListTile(
                      leading: Icon(
                        incident.latitude == null
                            ? Icons.location_off_outlined
                            : Icons.location_on_outlined,
                      ),
                      title: Text(incident.type),
                      subtitle: Text(
                        '${incident.location.isEmpty ? incident.description : incident.location}\n${_label(incident.status)} · ${_label(incident.priority)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.pop(context);
                        _showIncident(incident);
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _openExternalMap(Incident incident) async {
    final latitude = incident.latitude;
    final longitude = incident.longitude;
    if (latitude == null || longitude == null) return;
    final nativeUri = Uri.parse(
      'geo:$latitude,$longitude?q=$latitude,$longitude',
    );
    final browserUri = Uri.https('www.openstreetmap.org', '/', {
      'mlat': '$latitude',
      'mlon': '$longitude',
    });
    try {
      if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (await launchUrl(browserUri, mode: LaunchMode.externalApplication)) {
        return;
      }
      throw Exception('No hay una aplicación de mapas disponible');
    } on Exception catch (error) {
      if (mounted) _showMessage('No se pudo abrir la ubicación: $error');
    }
  }

  void _showIncident(Incident incident) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    incident.type,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                PillBadge(value: incident.status, compact: true),
                const SizedBox(width: 6),
                PillBadge(
                  value: incident.priority,
                  isPriority: true,
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (incident.description.isNotEmpty)
              Text(
                incident.description,
                style: const TextStyle(fontSize: 14, height: 1.45),
              ),
            if (incident.location.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.place_outlined,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      incident.location,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (incident.latitude != null && incident.longitude != null)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () => _openExternalMap(incident),
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: const Text('Abrir en mapas'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Marker> _buildIncidentMarkers(List<Incident> withLocation, bool isDark) {
    double currentZoom = 13.0;
    try {
      currentZoom = _mapController.camera.zoom;
    } catch (_) {
      currentZoom = 13.0;
    }

    if (currentZoom >= 12.0) {
      return withLocation.map((incident) {
        final color = _priorityColor(incident.priority);
        return Marker(
          point: LatLng(incident.latitude!, incident.longitude!),
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedIncident = incident);
              _showIncident(incident);
            },
            child: _ModernIncidentMarker(
              incident: incident,
              color: color,
              isDark: isDark,
            ),
          ),
        );
      }).toList();
    }

    // Agrupamiento espacial para vista panorámica
    final clusters = <List<Incident>>[];
    const threshold = 0.018;

    for (final inc in withLocation) {
      bool added = false;
      for (final cluster in clusters) {
        final ref = cluster.first;
        final dLat = (inc.latitude! - ref.latitude!).abs();
        final dLng = (inc.longitude! - ref.longitude!).abs();
        if (dLat < threshold && dLng < threshold) {
          cluster.add(inc);
          added = true;
          break;
        }
      }
      if (!added) {
        clusters.add([inc]);
      }
    }

    return clusters.map((group) {
      if (group.length == 1) {
        final incident = group.first;
        final color = _priorityColor(incident.priority);
        return Marker(
          point: LatLng(incident.latitude!, incident.longitude!),
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedIncident = incident);
              _showIncident(incident);
            },
            child: _ModernIncidentMarker(
              incident: incident,
              color: color,
              isDark: isDark,
            ),
          ),
        );
      }

      final avgLat =
          group.map((e) => e.latitude!).reduce((a, b) => a + b) / group.length;
      final avgLng =
          group.map((e) => e.longitude!).reduce((a, b) => a + b) / group.length;
      final centerPt = LatLng(avgLat, avgLng);

      return Marker(
        point: centerPt,
        width: 44,
        height: 44,
        child: _ClusterMarker(
          count: group.length,
          color: AppColors.brightBlue,
          isDark: isDark,
          onTap: () => _mapController.move(centerPt, 13.8),
        ),
      );
    }).toList();
  }

  Color _priorityColor(String priority) => switch (priority) {
        'CRITICAL' => const Color(0xFFEF4444),
        'HIGH' => const Color(0xFFF97316),
        'LOW' => const Color(0xFF10B981),
        _ => const Color(0xFF3B82F6),
      };
}

/// Marcador de cluster agrupado para vistas panorámicas del mapa
class _ClusterMarker extends StatelessWidget {
  const _ClusterMarker({
    required this.count,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  final int count;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark ? AppColors.darkCanvas : Colors.white,
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.45),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '+$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Marcador moderno circular y minimalista para incidentes reportados
class _ModernIncidentMarker extends StatelessWidget {
  const _ModernIncidentMarker({
    required this.incident,
    required this.color,
    required this.isDark,
  });

  final Incident incident;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final icon = _categoryIcon(incident.type);

    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.38),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(child: Icon(icon, size: 18, color: color)),
      ),
    );
  }

  IconData _categoryIcon(String type) {
    final upper = type.toUpperCase();
    if (upper.contains('ROBO') || upper.contains('HURTO')) {
      return Icons.shield_outlined;
    }
    if (upper.contains('ACCIDENTE') || upper.contains('TRANSITO')) {
      return Icons.directions_car_rounded;
    }
    if (upper.contains('INCENDIO') || upper.contains('FUEGO')) {
      return Icons.local_fire_department_rounded;
    }
    if (upper.contains('EMERGENCIA') || upper.contains('MEDIC')) {
      return Icons.medical_services_outlined;
    }
    if (upper.contains('PELEA') || upper.contains('ORDEN')) {
      return Icons.campaign_rounded;
    }
    return Icons.warning_amber_rounded;
  }
}

/// Marcador moderno de ubicación GPS del usuario con pulso radar continuo
class _ModernUserLocationMarker extends StatefulWidget {
  const _ModernUserLocationMarker();

  @override
  State<_ModernUserLocationMarker> createState() =>
      _ModernUserLocationMarkerState();
}

class _ModernUserLocationMarkerState extends State<_ModernUserLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final scale = 0.85 + (_anim.value * 1.15);
        final opacity = (1.0 - _anim.value).clamp(0.0, 1.0);
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Onda radar expansiva
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brightBlue.withValues(
                      alpha: 0.28 * opacity,
                    ),
                    border: Border.all(
                      color: AppColors.brightBlue.withValues(
                        alpha: 0.5 * opacity,
                      ),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              // Núcleo blanco y azul con sombra
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.brightBlue.withValues(alpha: 0.45),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 13,
                    height: 13,
                    decoration: const BoxDecoration(
                      color: AppColors.brightBlue,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Botón circular flotante estilo Glassmorphism para controles del mapa
class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
    this.isActive = false,
  });

  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? (isDark
            ? AppColors.brightBlue.withValues(alpha: 0.35)
            : AppColors.blue.withValues(alpha: 0.15))
        : (isDark
            ? AppColors.darkCard.withValues(alpha: 0.82)
            : Colors.white.withValues(alpha: 0.9));
    final borderColor = isActive
        ? (isDark ? AppColors.brightBlue : AppColors.blue)
        : (isDark ? AppColors.darkBorder : AppColors.border);
    final iconColor = isActive
        ? (isDark ? AppColors.brightBlue : AppColors.blue)
        : (isDark ? AppColors.darkText : AppColors.navy);

    return ClipOval(
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          tooltip: tooltip,
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: iconColor,
          icon: Icon(icon),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Modelo de datos para zonas distritales de Cartagena
class _MapZone {
  const _MapZone({
    required this.id,
    required this.name,
    required this.riskLevel,
    required this.center,
  });

  final String id;
  final String name;
  final String riskLevel;
  final LatLng center;

  factory _MapZone.fromJson(Map<String, dynamic> json) {
    return _MapZone(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'MODERATE',
      center: LatLng(
        (json['centerLatitude'] as num?)?.toDouble() ?? 10.391,
        (json['centerLongitude'] as num?)?.toDouble() ?? -75.4794,
      ),
    );
  }
}

Color _zoneColor(String risk) => switch (risk.toUpperCase()) {
      'LOW' => const Color(0xFF10B981),
      'HIGH' || 'CRITICAL' => const Color(0xFFEF4444),
      _ => const Color(0xFFF59E0B),
    };

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              const Text('No se pudieron cargar los incidentes'),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
}

/// Tarjeta flotante inferior de incidente cercano (Figma 03 · Mapa)
class _FigmaMapIncidentCard extends StatelessWidget {
  const _FigmaMapIncidentCard({
    required this.incident,
    required this.onTapReport,
  });

  final Incident? incident;
  final VoidCallback onTapReport;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (incident == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Cartagena sin alertas críticas cercanas',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Mapa de referencia · Datos en tiempo real',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    final inc = incident!;
    final (catName, catBg, catFg) = _getCatInfo(inc.type, isDark);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  catName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: catFg,
                  ),
                ),
              ),
              Text(
                'a 450 m de ti',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inc.description.isNotEmpty ? inc.description : inc.type,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkText : const Color(0xFF142C40),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${inc.location.isNotEmpty ? inc.location : "Cartagena"} · Hace 10 min',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: onTapReport,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver reporte',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'Mapa de referencia · Datos de sentido',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, Color) _getCatInfo(String type, bool isDark) {
    final lower = type.toLowerCase();
    if (lower.contains('traf') || lower.contains('movil') || lower.contains('accidente')) {
      return (
        'Movilidad',
        isDark ? const Color(0xFF451A03) : const Color(0xFFFFF4DC),
        isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A6200),
      );
    }
    if (lower.contains('segur') || lower.contains('robo') || lower.contains('sospech')) {
      return (
        'Seguridad',
        isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
        isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      );
    }
    if (lower.contains('vía') || lower.contains('via') || lower.contains('calle') || lower.contains('obra')) {
      return (
        'Vía cerrada',
        isDark ? const Color(0xFF064E3B) : const Color(0xFFE6F7EF),
        isDark ? const Color(0xFF34D399) : const Color(0xFF087554),
      );
    }
    return (
      'Incidente',
      isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE7F0F8),
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F4C81),
    );
  }
}
