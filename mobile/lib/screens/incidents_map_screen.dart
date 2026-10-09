import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../data/api_client.dart';
import '../data/models.dart';

class IncidentsMapScreen extends StatefulWidget {
  const IncidentsMapScreen({required this.api, super.key});

  final ApiClient api;

  @override
  State<IncidentsMapScreen> createState() => _IncidentsMapScreenState();
}

class _IncidentsMapScreenState extends State<IncidentsMapScreen> {
  late Future<List<Incident>> _incidents;

  @override
  void initState() {
    super.initState();
    _incidents = _loadIncidents();
  }

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

  void _reload() => setState(() => _incidents = _loadIncidents());

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
        final withLocation = incidents
            .where(
              (incident) =>
                  incident.latitude != null && incident.longitude != null,
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
                      'Incidentes en Cartagena',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
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
              child: FlutterMap(
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
                    markers: withLocation.map((incident) {
                      final color = _priorityColor(incident.priority);
                      return Marker(
                        point: LatLng(incident.latitude!, incident.longitude!),
                        width: 44,
                        height: 44,
                        child: IconButton(
                          tooltip: incident.type,
                          onPressed: () => _showIncident(incident),
                          icon: Icon(Icons.location_on, color: color, size: 38),
                        ),
                      );
                    }).toList(),
                  ),
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${incidents.length} reportes · ${withLocation.length} con ubicación',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        );
      },
    );
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
