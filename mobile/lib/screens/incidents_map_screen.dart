import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/api_client.dart';
import '../data/incident_filters.dart';
import '../data/location_service.dart';
import '../data/models.dart';

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
    setState(() => _locating = true);
    try {
      final position = await LocationService.currentPosition();
      if (!mounted) return;
      setState(() => _position = position);
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } on LocationAccessException catch (error) {
      _showLocationError(error);
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
                label: 'Abrir ajustes',
                onPressed: () async {
                  final opened = await LocationService.openSettings(
                    error.settingsTarget!,
                  );
                  if (!opened && mounted) {
                    _showMessage(
                      'No fue posible abrir los ajustes del sistema.',
                    );
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
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
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
                    options: const MapOptions(
                      initialCenter: LatLng(10.391, -75.4794),
                      initialZoom: 12,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName:
                            'com.cartagenasegura.cartagena_segura',
                      ),
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
                  Positioned(
                    right: 12,
                    bottom: 12,
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
