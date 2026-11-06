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
  MapTileTheme _tileTheme = MapTileTheme.auto;

  List<SafeRoute>? _safeRoutes;
  int _selectedRouteIndex = 0;
  DestinationPreset? _selectedDestination;
  bool _isRouting = false;
  bool _isSelectingDestinationOnMap = false;

  @override
  void initState() {
    super.initState();
    widget.incidentRefresh.addListener(_onIncidentRefresh);
    _incidents = _loadIncidents();
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
    widget.incidentRefresh.removeListener(_onIncidentRefresh);
    super.dispose();
  }

  void _onIncidentRefresh() => _reload();

  Future<List<Incident>> _loadIncidents() async {
    final response = await widget.api.get('Incidents');
    if (response is! List) {
      throw const FormatException(
        'La API devolvió una lista de incidentes inválida',
      );
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(Incident.fromJson)
        .toList();
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

  void _closeRoute() {
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
        final filtered = filterIncidents(
          incidents,
          type: _typeFilter,
          status: _statusFilter,
          priority: _priorityFilter,
        );
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

        return Stack(
          children: [
            // Mapa a pantalla completa
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(10.391, -75.4794),
                initialZoom: 12.5,
                onTap: (tapPosition, point) => _onMapTap(point),
              ),
              children: [
                if (isDarkMap)
                  darkModeTilesContainerBuilder(
                    context,
                    TileLayer(
                      urlTemplate: urlTemplate,
                      userAgentPackageName:
                          'com.cartagenasegura.cartagena_segura',
                    ),
                  )
                else
                  TileLayer(
                    urlTemplate: urlTemplate,
                    userAgentPackageName:
                        'com.cartagenasegura.cartagena_segura',
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
                            borderColor: isDark
                                ? Colors.black54
                                : Colors.white70,
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

                // Marcadores de incidentes reportados
                MarkerLayer(
                  markers: [
                    ...withLocation.map((incident) {
                      final color = _priorityColor(incident.priority);
                      return Marker(
                        point: LatLng(incident.latitude!, incident.longitude!),
                        width: 42,
                        height: 42,
                        child: GestureDetector(
                          onTap: () => _showIncident(incident),
                          child: _ModernIncidentMarker(
                            incident: incident,
                            color: color,
                            isDark: isDark,
                          ),
                        ),
                      );
                    }),
                    // Marcador GPS de ubicación actual del usuario
                    if (_position case final position?)
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

            // Barra flotante superior estilo Glassmorphism
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkCard.withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.35 : 0.08,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Badge indicador con pulso
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${withLocation.length} en mapa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.navy,
                          ),
                        ),
                      ),
                      // Botón Filtros
                      IconButton(
                        tooltip: 'Filtrar incidentes',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showFilters(context),
                        icon: Badge(
                          isLabelVisible:
                              _typeFilter != null ||
                              _statusFilter != null ||
                              _priorityFilter != null,
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 20,
                            color: isDark ? AppColors.darkText : AppColors.navy,
                          ),
                        ),
                      ),
                      // Botón Estilo de Mapa
                      IconButton(
                        tooltip: 'Cambiar estilo de mapa',
                        visualDensity: VisualDensity.compact,
                        onPressed: _cycleTileTheme,
                        icon: Icon(
                          switch (_tileTheme) {
                            MapTileTheme.auto => Icons.auto_mode_rounded,
                            MapTileTheme.light => Icons.wb_sunny_outlined,
                            MapTileTheme.dark => Icons.nightlight_round,
                            MapTileTheme.satellite =>
                              Icons.satellite_alt_outlined,
                          },
                          size: 20,
                          color: isDark ? AppColors.sky : AppColors.brightBlue,
                        ),
                      ),
                      // Botón Lista accesible
                      IconButton(
                        tooltip: 'Ver lista accesible de incidentes',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _showIncidentList(filtered),
                        icon: Icon(
                          Icons.format_list_bulleted_rounded,
                          size: 20,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                      // Botón Actualizar
                      IconButton(
                        tooltip: 'Actualizar incidentes',
                        visualDensity: VisualDensity.compact,
                        onPressed: _reload,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Botón flotante para Trazar Ruta Segura estilo Waze
            if (!_isSelectingDestinationOnMap && _safeRoutes == null)
              Positioned(
                top: 76,
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

            // Barra lateral flotante de controles (Zoom + Mi Ubicación)
            Positioned(
              right: 14,
              bottom: _safeRoutes != null ? 240 : 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                          color: AppColors.brightBlue.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FloatingActionButton.small(
                      heroTag: 'locate_me_fab',
                      tooltip: 'Mi ubicación GPS',
                      backgroundColor: AppColors.brightBlue,
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

            // Alerta discreta en esquina inferior si hay reportes sin coordenadas
            if (withoutLocation.isNotEmpty && _safeRoutes == null)
              Positioned(
                left: 14,
                bottom: 20,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showIncidentList(withoutLocation),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkCard.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.border,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off_outlined,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${withoutLocation.length} sin GPS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tarjeta HUD de la Ruta Segura activa (Estilo Waze)
            if (_safeRoutes case final routes? when routes.isNotEmpty)
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
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _showFilters(BuildContext context) async {
    var type = _typeFilter;
    var status = _statusFilter;
    var priority = _priorityFilter;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Filtrar incidentes',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _filterDropdown(
                  label: 'Tipo',
                  value: type,
                  values: const [
                    'ROBO',
                    'ACCIDENTE',
                    'PELEA',
                    'INCENDIO',
                    'EMERGENCIA',
                    'OTRO',
                  ],
                  onChanged: (value) => update(() => type = value),
                ),
                _filterDropdown(
                  label: 'Estado',
                  value: status,
                  values: const [
                    'PENDING',
                    'IN_PROGRESS',
                    'RESOLVED',
                    'REJECTED',
                  ],
                  onChanged: (value) => update(() => status = value),
                ),
                _filterDropdown(
                  label: 'Prioridad',
                  value: priority,
                  values: const ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
                  onChanged: (value) => update(() => priority = value),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        update(() {
                          type = null;
                          status = null;
                          priority = null;
                        });
                      },
                      child: const Text('Limpiar'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Aplicar'),
                    ),
                  ],
                ),
              ],
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
      });
    }
  }

  Widget _filterDropdown({
    required String label,
    required String? value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) => DropdownButtonFormField<String>(
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
            Text(incident.type, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (incident.description.isNotEmpty) Text(incident.description),
            if (incident.location.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Ubicación: ${incident.location}'),
            ],
            const SizedBox(height: 8),
            Text(
              'Estado: ${incident.status} · Prioridad: ${incident.priority}',
            ),
            if (incident.latitude != null && incident.longitude != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _openExternalMap(incident),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Abrir en mapas'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(String priority) => switch (priority) {
    'CRITICAL' => const Color(0xFFEF4444),
    'HIGH' => const Color(0xFFF97316),
    'LOW' => const Color(0xFF10B981),
    _ => const Color(0xFF3B82F6),
  };
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

/// Marcador moderno de ubicación GPS del usuario con pulso radar
class _ModernUserLocationMarker extends StatelessWidget {
  const _ModernUserLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo exterior traslúcido
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brightBlue.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
          ),
          // Núcleo blanco y azul
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brightBlue.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
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
  }
}

/// Botón circular flotante para controles del mapa
class _FloatingMapButton extends StatelessWidget {
  const _FloatingMapButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isDark;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
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
        color: isDark ? AppColors.darkText : AppColors.navy,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}

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
