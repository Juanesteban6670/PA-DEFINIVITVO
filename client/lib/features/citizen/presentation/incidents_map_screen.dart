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
      if (error.isPermissionBlocked || (kIsWeb && error.settingsTarget != null)) {
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
        padding: const EdgeInsets.fromLTRB(40, 80, 40, 200),
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

  @override
  Widget build(BuildContext context) {
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Incidentes (${filtered.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Filtrar incidentes',
                    onPressed: () => _showFilters(context),
                    icon: Badge(
                      isLabelVisible:
                          _typeFilter != null ||
                          _statusFilter != null ||
                          _priorityFilter != null,
                      child: const Icon(Icons.filter_list),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Ver lista accesible de incidentes',
                    onPressed: () => _showIncidentList(filtered),
                    icon: const Icon(Icons.list_alt),
                  ),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(10.391, -75.4794),
                      initialZoom: 12,
                      onTap: (tapPosition, point) => _onMapTap(point),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.cartagenasegura.cartagena_segura',
                      ),
                      if (_safeRoutes case final routes? when routes.isNotEmpty) ...[
                        PolylineLayer(
                          polylines: [
                            for (var i = 0; i < routes.length; i++)
                              if (i != _selectedRouteIndex)
                                Polyline(
                                  points: routes[i].points,
                                  strokeWidth: 4.0,
                                  color: const Color(0xFF94A3B8),
                                  borderColor: Colors.white,
                                  borderStrokeWidth: 1.0,
                                ),
                            Polyline(
                              points: routes[_selectedRouteIndex].points,
                              strokeWidth: 6.0,
                              color: _routeColor(routes[_selectedRouteIndex].safetyLevel),
                              borderColor: Colors.white,
                              borderStrokeWidth: 2.0,
                            ),
                          ],
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: routes[_selectedRouteIndex].points.first,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D4ED8),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.navigation, color: Colors.white, size: 18),
                              ),
                            ),
                            Marker(
                              point: routes[_selectedRouteIndex].points.last,
                              width: 36,
                              height: 36,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.flag, color: Colors.white, size: 18),
                              ),
                            ),
                            for (final hazard in routes[_selectedRouteIndex].hazardsOnRoute)
                              Marker(
                                point: LatLng(hazard.latitude!, hazard.longitude!),
                                width: 32,
                                height: 32,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFDC2626), width: 1.5),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                  ),
                                  child: const Icon(
                                    Icons.warning_amber_rounded,
                                    color: Color(0xFFDC2626),
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      MarkerLayer(
                        markers: [
                          ...withLocation.map((incident) {
                            final color = _priorityColor(incident.priority);
                            return Marker(
                              point: LatLng(
                                incident.latitude!,
                                incident.longitude!,
                              ),
                              width: 44,
                              height: 44,
                              child: IconButton(
                                tooltip: incident.type,
                                onPressed: () => _showIncident(incident),
                                icon: Icon(
                                  Icons.location_on,
                                  color: color,
                                  size: 38,
                                ),
                              ),
                            );
                          }),
                          if (_position case final position?)
                            Marker(
                              point: LatLng(
                                position.latitude,
                                position.longitude,
                              ),
                              width: 44,
                              height: 44,
                              child: const Icon(
                                Icons.my_location,
                                color: Color(0xFF1D4ED8),
                                size: 30,
                              ),
                            ),
                        ],
                      ),
                      const RichAttributionWidget(
                        attributions: [
                          TextSourceAttribution('OpenStreetMap contributors'),
                        ],
                      ),
                    ],
                  ),

                  // Botón flotante para Trazar Ruta
                  if (!_isSelectingDestinationOnMap && _safeRoutes == null)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1D4ED8),
                          foregroundColor: Colors.white,
                          elevation: 4,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        onPressed: _openDestinationSearch,
                        icon: const Icon(Icons.alt_route, size: 18),
                        label: const Text(
                          'Trazar Ruta Segura',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),

                  // Banner informativo para elegir destino en el mapa
                  if (_isSelectingDestinationOnMap)
                    Positioned(
                      top: 12,
                      left: 12,
                      right: 12,
                      child: Material(
                        elevation: 6,
                        borderRadius: BorderRadius.circular(14),
                        color: const Color(0xFF0F172A),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.touch_app, color: Colors.amberAccent, size: 20),
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
                                icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                                onPressed: () => setState(() => _isSelectingDestinationOnMap = false),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // Indicador de cálculo de rutas
                  if (_isRouting)
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Calculando rutas e índices de seguridad…',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Botón Mi ubicación
                  Positioned(
                    right: 12,
                    bottom: _safeRoutes != null ? 220 : 12,
                    child: FilledButton.tonalIcon(
                      onPressed: _locating ? null : _locateMe,
                      icon: _locating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_locating ? 'Buscando…' : 'Mi ubicación'),
                    ),
                  ),

                  // Tarjeta HUD de la Ruta Segura activa
                  if (_safeRoutes case final routes? when routes.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: SafeRouteSheet(
                          routes: routes,
                          selectedRouteIndex: _selectedRouteIndex,
                          destinationName: _selectedDestination?.name ?? 'Destino seleccionado',
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Column(
                children: [
                  Text(
                    '${filtered.length} reportes · ${withLocation.length} en el mapa',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (withoutLocation.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _showIncidentList(withoutLocation),
                      icon: const Icon(Icons.location_off_outlined, size: 18),
                      label: Text(
                        '${withoutLocation.length} sin coordenadas: ver lista',
                      ),
                    ),
                ],
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
      DropdownMenuItem<String>(value: null, child: Text('Todos')),
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
    'CRITICAL' => const Color(0xFFB42318),
    'HIGH' => const Color(0xFFDC6803),
    'LOW' => const Color(0xFF039855),
    _ => const Color(0xFF155EEF),
  };
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
