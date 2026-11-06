import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/session_controller.dart';
import 'package:cartagena_segura/shared/notifications_bell.dart';
import 'package:cartagena_segura/shared/theme.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({
    required this.session,
    required this.location,
    this.initialIncidentId,
    super.key,
  });

  final SessionController session;
  final String location;
  final String? initialIncidentId;

  static const _sections = [
    ('/Admin', 'Resumen', Icons.dashboard_outlined),
    ('/Admin/Incidents', 'Incidentes', Icons.report_outlined),
    ('/Admin/Zones', 'Zonas', Icons.map_outlined),
    ('/Admin/Logs', 'Auditoría', Icons.receipt_long_outlined),
    ('/Admin/Emergency', 'Emergencias', Icons.phone_in_talk_outlined),
    ('/Admin/Reports', 'Reportes', Icons.query_stats_outlined),
    ('/Admin/Ai', 'Inteligencia', Icons.auto_awesome_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = _sections.indexWhere((section) => section.$1 == location);
    final selectedIndex = selected < 0 ? 0 : selected;
    final wide = MediaQuery.sizeOf(context).width >= 850;
    return Scaffold(
      appBar: AppBar(
        title: Text(_sections[selectedIndex].$2),
        actions: [
          const ThemeToggleButton(),
          NotificationsBell(
            api: session.api,
            onPressed: () => context.push('/App/Notifications'),
          ),
          Text(
            session.user?.fullName ?? '',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await session.logout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    const DrawerHeader(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Administración',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    for (var index = 0; index < _sections.length; index++)
                      ListTile(
                        selected: selectedIndex == index,
                        leading: Icon(_sections[index].$3),
                        title: Text(_sections[index].$2),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(_sections[index].$1);
                        },
                      ),
                  ],
                ),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: selectedIndex,
              extended: MediaQuery.sizeOf(context).width >= 1100,
              onDestinationSelected: (index) => context.go(_sections[index].$1),
              destinations: [
                for (final section in _sections)
                  NavigationRailDestination(
                    icon: Icon(section.$3),
                    label: Text(section.$2),
                  ),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: AdminSectionPage(
              key: ValueKey(location),
              api: session.api,
              location: location,
              initialIncidentId: initialIncidentId,
            ),
          ),
        ],
      ),
      floatingActionButton: wide
          ? null
          : Builder(
              builder: (context) => FloatingActionButton.small(
                tooltip: 'Abrir menú de administración',
                onPressed: () => Scaffold.of(context).openDrawer(),
                child: const Icon(Icons.menu),
              ),
            ),
    );
  }
}

class AdminSectionPage extends StatefulWidget {
  const AdminSectionPage({
    required this.api,
    required this.location,
    this.initialIncidentId,
    super.key,
  });

  final ApiClient api;
  final String location;
  final String? initialIncidentId;

  @override
  State<AdminSectionPage> createState() => _AdminSectionPageState();
}

class _AdminSectionPageState extends State<AdminSectionPage> {
  late Future<dynamic> _data;
  String _search = '';
  String _statusFilter = 'ALL';
  String? _openedIncidentId;
  bool _resolvingIncident = false;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<dynamic> _load() {
    switch (widget.location) {
      case '/Admin':
        return Future.wait([
          widget.api.get('Incidents'),
          widget.api.get('Zones'),
          widget.api.get('Ai/Summary'),
        ]);
      case '/Admin/Incidents':
        return widget.api.get('Incidents');
      case '/Admin/Zones':
        return widget.api.get('Zones');
      case '/Admin/Logs':
        return widget.api.get('Logs');
      case '/Admin/Emergency':
        return widget.api.get('EmergencyContacts');
      case '/Admin/Ai':
        return Future.wait([
          widget.api.get('Ai/Summary'),
          widget.api.get('Ai/Zones/Analysis'),
        ]);
      default:
        return Future<void>.value();
    }
  }

  void _reload() => setState(() => _data = _load());

  @override
  Widget build(BuildContext context) {
    if (widget.location == '/Admin/Reports') {
      return _reports(context);
    }
    return FutureBuilder<dynamic>(
      future: _data,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _error(context, snapshot.error!);
        }
        final value = snapshot.data;
        return switch (widget.location) {
          '/Admin' => _dashboard(context, value as List<dynamic>),
          '/Admin/Incidents' => _incidents(context, _maps(value)),
          '/Admin/Zones' => _zones(context, _maps(value)),
          '/Admin/Logs' => _logs(context, _maps(value)),
          '/Admin/Emergency' => _emergency(context, _maps(value)),
          '/Admin/Ai' => _ai(context, value as List<dynamic>),
          _ => const Center(child: Text('Sección no disponible')),
        };
      },
    );
  }

  Widget _error(BuildContext context, Object error) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44),
          const SizedBox(height: 12),
          const Text('No se pudo cargar la información'),
          const SizedBox(height: 8),
          Text('$error', textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );

  Widget _page(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget child,
    Widget? action,
  }) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(subtitle),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          ?action,
        ],
      ),
      const SizedBox(height: 18),
      child,
    ],
  );

  Widget _dashboard(BuildContext context, List<dynamic> results) {
    final incidents = _maps(results[0]);
    final zones = _maps(results[1]);
    final summary = results[2];
    final counts = <String, int>{};
    for (final incident in incidents) {
      final status = _string(incident['status'], 'PENDING');
      counts.update(status, (count) => count + 1, ifAbsent: () => 1);
    }
    return _page(
      context,
      title: 'Panel de control',
      subtitle: 'Resumen operativo de Cartagena Segura',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _metric(
                context,
                'Incidentes',
                '${incidents.length}',
                Icons.report,
              ),
              _metric(context, 'Zonas activas', '${zones.length}', Icons.map),
              _metric(
                context,
                'Pendientes',
                '${counts['PENDING'] ?? 0}',
                Icons.pending_actions,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Incidentes por estado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        barGroups: [
                          for (var index = 0; index < _statuses.length; index++)
                            BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: (counts[_statuses[index]] ?? 0)
                                      .toDouble(),
                                  color: AppColors.blue,
                                  width: 22,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                        ],
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= _statuses.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    _statusLabel(_statuses[index]),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (summary != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(_pretty(summary)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: AppColors.blue, size: 28),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  void _exportIncidentsToCsv(
    BuildContext context,
    List<Map<String, dynamic>> items,
  ) {
    if (items.isEmpty) {
      _notify(context, 'No hay incidentes para exportar.');
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'ID,Tipo,Descripcion,Ubicacion,Latitud,Longitud,Prioridad,Estado,FechaCreacion,ReportadoPor',
    );

    for (final inc in items) {
      final id = _escapeCsv(inc['id']?.toString() ?? '');
      final type = _escapeCsv(inc['type']?.toString() ?? '');
      final desc = _escapeCsv(inc['description']?.toString() ?? '');
      final loc = _escapeCsv(inc['location']?.toString() ?? '');
      final lat = inc['latitude']?.toString() ?? '';
      final lon = inc['longitude']?.toString() ?? '';
      final prio = _escapeCsv(inc['priority']?.toString() ?? '');
      final status = _escapeCsv(inc['status']?.toString() ?? '');
      final date = _escapeCsv(inc['createdAt']?.toString() ?? '');
      final rep = _escapeCsv(inc['reportedBy']?.toString() ?? '');

      buffer.writeln('$id,$type,$desc,$loc,$lat,$lon,$prio,$status,$date,$rep');
    }

    final csvContent = buffer.toString();
    final bytes = utf8.encode(csvContent);
    final base64Csv = base64Encode(bytes);
    final dataUri = 'data:text/csv;charset=utf-8;base64,$base64Csv';
    launchUrl(Uri.parse(dataUri));

    _notify(
      context,
      'Archivo CSV exportado exitosamente (${items.length} registros)',
    );
  }

  String _escapeCsv(String val) {
    if (val.contains(',') ||
        val.contains('"') ||
        val.contains('\n') ||
        val.contains('\r')) {
      return '"${val.replaceAll('"', '""')}"';
    }
    return val;
  }

  Widget _incidents(
    BuildContext context,
    List<Map<String, dynamic>> incidents,
  ) {
    _openInitialIncidentIfAvailable(context, incidents);
    final searched = _filter(incidents, const [
      'type',
      'description',
      'location',
      'status',
    ]);
    final visible = _statusFilter == 'ALL'
        ? searched
        : searched
              .where((incident) => incident['status'] == _statusFilter)
              .toList(growable: false);
    return _page(
      context,
      title: 'Incidentes',
      subtitle: '${visible.length} registros',
      action: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
        ),
        onPressed: () => _exportIncidentsToCsv(context, visible),
        icon: const Icon(Icons.file_download_outlined, size: 18),
        label: const Text('Exportar CSV'),
      ),
      child: Column(
        children: [
          _searchField(),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final status in const [
                  'ALL',
                  'PENDING',
                  'IN_PROGRESS',
                  'RESOLVED',
                  'REJECTED',
                ])
                  FilterChip(
                    label: Text(
                      status == 'ALL' ? 'Todos' : _statusLabel(status),
                    ),
                    selected: _statusFilter == status,
                    onSelected: (_) => setState(() => _statusFilter = status),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const _EmptyState(message: 'No hay incidentes para mostrar.')
          else
            for (final incident in visible)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.report_gmailerrorred_outlined),
                  ),
                  onTap: () => _showIncident(context, incident),
                  title: Text(_string(incident['type'], 'Incidente')),
                  subtitle: Text(
                    '${_string(incident['description'])}\n${_string(incident['location'])} · ${_statusLabel(_string(incident['status'], 'PENDING'))} · ${_string(incident['priority'], 'MEDIUM')}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Acciones del incidente',
                    onSelected: (action) =>
                        _incidentAction(context, incident, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'manage',
                        child: Text('Estado y asignación'),
                      ),
                      const PopupMenuItem(
                        value: 'history',
                        child: Text('Historial de cambios'),
                      ),
                      const PopupMenuItem(
                        value: 'comments',
                        child: Text('Ver comentarios'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar'),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  void _openInitialIncidentIfAvailable(
    BuildContext context,
    List<Map<String, dynamic>> incidents,
  ) {
    final id = widget.initialIncidentId;
    if (id == null ||
        id.isEmpty ||
        _openedIncidentId == id ||
        _resolvingIncident) {
      return;
    }
    final incident = incidents.where((item) => _string(item['id']) == id);
    if (incident.isNotEmpty) {
      _openedIncidentId = id;
      final selected = incident.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) _showIncident(context, selected);
      });
      return;
    }
    _resolvingIncident = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !context.mounted) return;
      try {
        final response = await widget.api.get('Incidents/$id');
        if (!mounted || !context.mounted) return;
        if (response is! Map<String, dynamic>) {
          throw const FormatException('La API devolvió un incidente no válido');
        }
        _openedIncidentId = id;
        await _showIncident(context, response);
      } on Exception catch (error) {
        if (mounted && context.mounted) {
          _notify(context, 'No se pudo abrir el incidente: $error');
        }
      } finally {
        _resolvingIncident = false;
        _openedIncidentId = id;
      }
    });
  }

  Future<void> _incidentAction(
    BuildContext context,
    Map<String, dynamic> incident,
    String action,
  ) async {
    final id = _string(incident['id']);
    if (id.isEmpty) return;
    try {
      if (action == 'manage') {
        await _manageIncident(context, incident);
        return;
      } else if (action == 'delete') {
        final confirmed = await _confirm(context, '¿Eliminar este incidente?');
        if (confirmed != true || !context.mounted || !mounted) return;
        await widget.api.delete('Incidents/$id');
      } else if (action == 'history') {
        await _showHistory(context, id);
        return;
      } else if (action == 'comments') {
        await showDialog<void>(
          context: context,
          builder: (_) => _CommentsDialog(api: widget.api, incidentId: id),
        );
        return;
      }
      if (!context.mounted || !mounted) return;
      _notify(context, 'Cambios guardados');
      _reload();
    } on Exception catch (error) {
      if (!context.mounted || !mounted) return;
      _notify(context, 'No se pudo actualizar el incidente: $error');
    }
  }

  Future<void> _manageIncident(
    BuildContext context,
    Map<String, dynamic> incident,
  ) async {
    final assignedTo = TextEditingController(
      text: _string(incident['assignedTo']),
    );
    final reason = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var status = _string(incident['status'], 'PENDING');
    var priority = _string(incident['priority'], 'MEDIUM');
    try {
      final update = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Gestionar incidente'),
            content: SizedBox(
              width: 440,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: _statuses
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(_statusLabel(value)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => status = value);
                        }
                      },
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: priority,
                      decoration: const InputDecoration(labelText: 'Prioridad'),
                      items: _priorities
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => priority = value);
                        }
                      },
                    ),
                    _textField(assignedTo, 'Usuario asignado (opcional)'),
                    _textField(reason, 'Motivo del cambio', required: true),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, {
                    'status': status,
                    'priority': priority,
                    'assignedTo': assignedTo.text.trim(),
                    'changeReason': reason.text.trim(),
                  });
                },
                child: const Text('Guardar cambios'),
              ),
            ],
          ),
        ),
      );
      if (update == null || !context.mounted || !mounted) return;
      final id = _string(incident['id']);
      await widget.api.patch('Incidents/$id/Status', update);
      if (!context.mounted || !mounted) return;
      _notify(context, 'Incidente actualizado');
      _reload();
    } on Exception catch (error) {
      if (!context.mounted || !mounted) return;
      _notify(context, 'No se pudo actualizar el incidente: $error');
    } finally {
      assignedTo.dispose();
      reason.dispose();
    }
  }

  Future<void> _showIncident(
    BuildContext context,
    Map<String, dynamic> incident,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_string(incident['type'], 'Incidente')),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_string(incident['description'])),
              const SizedBox(height: 12),
              Text('Ubicación: ${_string(incident['location'])}'),
              Text('Reportado por: ${_string(incident['reportedBy'])}'),
              Text(
                'Asignado a: ${_string(incident['assignedTo'], 'Sin asignar')}',
              ),
              Text(
                'Estado: ${_statusLabel(_string(incident['status'], 'PENDING'))}',
              ),
              Text('Prioridad: ${_string(incident['priority'], 'MEDIUM')}'),
              Text('Fecha: ${_string(incident['createdAt'])}'),
              if (incident['latitude'] != null && incident['longitude'] != null)
                Text(
                  'Coordenadas: ${incident['latitude']}, ${incident['longitude']}',
                ),
              for (final url
                  in (incident['imageUrls'] as List? ?? const [])
                      .whereType<String>())
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 260),
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) =>
                          const Text('No se pudo cargar una imagen adjunta.'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );

  Future<void> _showHistory(BuildContext context, String incidentId) async {
    try {
      final history = await widget.api.get('Incidents/$incidentId/History');
      if (!context.mounted) return;
      final entries = history is List
          ? history.whereType<Map<String, dynamic>>().toList()
          : const <Map<String, dynamic>>[];
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Historial del incidente'),
          content: SizedBox(
            width: 520,
            height: 360,
            child: entries.isEmpty
                ? const Center(child: Text('No hay cambios registrados.'))
                : ListView(
                    children: [
                      for (final entry in entries)
                        ListTile(
                          title: Text(
                            '${entry['previousStatus'] ?? ''} → ${entry['newStatus'] ?? entry['status'] ?? ''}',
                          ),
                          subtitle: Text(
                            '${entry['changeReason'] ?? entry['reason'] ?? ''}\n${entry['changedBy'] ?? ''} · ${entry['changedAt'] ?? entry['createdAt'] ?? ''}',
                          ),
                        ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } on Exception catch (error) {
      if (!context.mounted) return;
      _notify(context, 'No se pudo cargar el historial: $error');
    }
  }

  Widget _zones(BuildContext context, List<Map<String, dynamic>> zones) {
    final visible = _filter(zones, const ['name', 'description', 'riskLevel']);
    return _page(
      context,
      title: 'Zonas de riesgo',
      subtitle: '${visible.length} zonas activas',
      action: FilledButton.icon(
        onPressed: () => _createZone(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva zona'),
      ),
      child: Column(
        children: [
          _searchField(),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const _EmptyState(message: 'No hay zonas para mostrar.')
          else
            for (final zone in visible)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.location_city)),
                  title: Text(_string(zone['name'], 'Zona')),
                  subtitle: Text(
                    '${_string(zone['description'])}\nRiesgo: ${_string(zone['riskLevel'], 'LOW')}',
                  ),
                  isThreeLine: true,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Administrar zona',
                    onSelected: (value) => _zoneAction(context, zone, value),
                    itemBuilder: (context) => [
                      for (final risk in _risks)
                        PopupMenuItem(
                          value: 'risk:$risk',
                          child: Text('Riesgo $risk'),
                        ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Desactivar zona'),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _createZone(BuildContext context) async {
    final name = TextEditingController();
    final description = TextEditingController();
    final latitude = TextEditingController();
    final longitude = TextEditingController();
    final formKey = GlobalKey<FormState>();
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Crear zona'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _textField(name, 'Nombre', required: true),
                  _textField(description, 'Descripción'),
                  _textField(latitude, 'Latitud', required: true, number: true),
                  _textField(
                    longitude,
                    'Longitud',
                    required: true,
                    number: true,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, {
                  'name': name.text.trim(),
                  'description': description.text.trim(),
                  'centerLatitude': double.parse(latitude.text),
                  'centerLongitude': double.parse(longitude.text),
                });
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      );
      if (!mounted || !context.mounted) return;
      if (result == null) return;
      await widget.api.post('Zones', result);
      if (!mounted || !context.mounted) return;
      _notify(context, 'Zona creada');
      _reload();
    } on Exception catch (error) {
      if (!mounted || !context.mounted) return;
      _notify(context, 'No se pudo crear la zona: $error');
    } finally {
      name.dispose();
      description.dispose();
      latitude.dispose();
      longitude.dispose();
    }
  }

  Future<void> _zoneAction(
    BuildContext context,
    Map<String, dynamic> zone,
    String action,
  ) async {
    final id = _string(zone['id']);
    if (id.isEmpty) return;
    try {
      if (action.startsWith('risk:')) {
        await widget.api.patch(
          'Zones/$id/Risk?riskLevel=${action.substring(5)}',
        );
      } else {
        if (await _confirm(context, '¿Desactivar esta zona?') != true) return;
        if (!mounted || !context.mounted) return;
        await widget.api.delete('Zones/$id');
      }
      if (!mounted || !context.mounted) return;
      _notify(context, 'Cambios guardados');
      _reload();
    } on Exception catch (error) {
      if (!mounted || !context.mounted) return;
      _notify(context, 'No se pudo actualizar la zona: $error');
    }
  }

  Widget _emergency(BuildContext context, List<Map<String, dynamic>> contacts) {
    final visible = _filter(contacts, const ['name', 'phone', 'type', 'zone']);
    return _page(
      context,
      title: 'Contactos de emergencia',
      subtitle: '${visible.length} contactos activos',
      action: FilledButton.icon(
        onPressed: () => _createContact(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo contacto'),
      ),
      child: Column(
        children: [
          _searchField(),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const _EmptyState(message: 'No hay contactos para mostrar.')
          else
            for (final contact in visible)
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.phone_in_talk_outlined),
                  ),
                  title: Text(_string(contact['name'], 'Contacto')),
                  subtitle: Text(
                    '${_string(contact['type'])} · ${_string(contact['zone'])}\n${_string(contact['phone'])}',
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    tooltip: 'Desactivar contacto',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteContact(context, contact),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _createContact(BuildContext context) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final alternativePhone = TextEditingController();
    final zone = TextEditingController();
    final address = TextEditingController();
    final notes = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var type = 'POLICE';
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Nuevo contacto'),
            content: SizedBox(
              width: 460,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _textField(name, 'Nombre', required: true),
                      _textField(phone, 'Teléfono', required: true),
                      _textField(alternativePhone, 'Teléfono alternativo'),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'Tipo'),
                        items:
                            const [
                                  'POLICE',
                                  'FIRE_STATION',
                                  'CIVIL_DEFENSE',
                                  'HOSPITAL',
                                  'AMBULANCE',
                                  'COAST_GUARD',
                                  'MUNICIPALITY',
                                  'OTHER',
                                ]
                                .map(
                                  (item) => DropdownMenuItem(
                                    value: item,
                                    child: Text(item),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => type = value);
                          }
                        },
                      ),
                      _textField(zone, 'Zona'),
                      _textField(address, 'Dirección'),
                      _textField(notes, 'Notas'),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(context, {
                    'name': name.text.trim(),
                    'phone': phone.text.trim(),
                    'alternativePhone': alternativePhone.text.trim(),
                    'type': type,
                    'zone': zone.text.trim(),
                    'address': address.text.trim(),
                    'notes': notes.text.trim(),
                  });
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        ),
      );
      if (!mounted || !context.mounted) return;
      if (result == null) return;
      await widget.api.post('EmergencyContacts', result);
      if (!mounted || !context.mounted) return;
      _notify(context, 'Contacto creado');
      _reload();
    } on Exception catch (error) {
      if (!mounted || !context.mounted) return;
      _notify(context, 'No se pudo crear el contacto: $error');
    } finally {
      for (final controller in [
        name,
        phone,
        alternativePhone,
        zone,
        address,
        notes,
      ]) {
        controller.dispose();
      }
    }
  }

  Future<void> _deleteContact(
    BuildContext context,
    Map<String, dynamic> contact,
  ) async {
    if (await _confirm(context, '¿Desactivar este contacto?') != true) return;
    if (!mounted || !context.mounted) return;
    try {
      await widget.api.delete('EmergencyContacts/${contact['id']}');
      if (!mounted || !context.mounted) return;
      _notify(context, 'Contacto desactivado');
      _reload();
    } on Exception catch (error) {
      if (!mounted || !context.mounted) return;
      _notify(context, 'No se pudo desactivar el contacto: $error');
    }
  }

  Widget _logs(BuildContext context, List<Map<String, dynamic>> logs) {
    final visible = _filter(logs, const [
      'username',
      'action',
      'description',
      'level',
      'entityType',
    ]);
    return _page(
      context,
      title: 'Auditoría del sistema',
      subtitle: '${visible.length} eventos',
      child: Column(
        children: [
          _searchField(),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const _EmptyState(message: 'No hay eventos para mostrar.')
          else
            for (final log in visible)
              Card(
                child: ListTile(
                  leading: Icon(
                    _string(log['level']) == 'ERROR'
                        ? Icons.error_outline
                        : Icons.history,
                  ),
                  title: Text(
                    '${_string(log['action'], 'Evento')} · ${_string(log['username'], 'Sistema')}',
                  ),
                  subtitle: Text(
                    '${_string(log['description'])}\n${_string(log['timestamp'] ?? log['createdAt'])}',
                  ),
                  isThreeLine: true,
                ),
              ),
        ],
      ),
    );
  }

  Widget _reports(BuildContext context) => _page(
    context,
    title: 'Reportes y análisis',
    subtitle: 'Tablero analítico externo del sistema',
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.query_stats_outlined,
              size: 36,
              color: AppColors.blue,
            ),
            const SizedBox(height: 12),
            Text(
              'Estadísticas del sistema',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'El tablero de Power BI se abre en una pestaña o aplicación externa. Su disponibilidad depende de los permisos de publicación del informe.',
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                final uri = Uri.parse(
                  'https://app.powerbi.com/view?r=eyJrIjoiNmZiOGI1NWMtMjEzYi00ZmFiLWE2Y2MtZjVmMDdjMGE5ZjVmIiwidCI6IjlkMTJiZjNmLWU0ZjYtNDdhYi05MTJmLTFhMmYwZmM0OGFhNCIsImMiOjR9',
                );
                final opened = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && context.mounted) {
                  _notify(context, 'No se pudo abrir el tablero externo');
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir tablero'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _ai(BuildContext context, List<dynamic> data) => _page(
    context,
    title: 'Inteligencia artificial',
    subtitle: 'Resumen de incidentes y análisis de zonas',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < data.length; index++)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(_pretty(data[index])),
            ),
          ),
        _AdminClassifier(api: widget.api),
        _AdminChat(api: widget.api),
      ],
    ),
  );

  Widget _searchField() => TextField(
    decoration: const InputDecoration(
      prefixIcon: Icon(Icons.search),
      labelText: 'Buscar',
      border: OutlineInputBorder(),
    ),
    onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
  );

  List<Map<String, dynamic>> _filter(
    List<Map<String, dynamic>> items,
    List<String> fields,
  ) {
    if (_search.isEmpty) return items;
    return items
        .where((item) {
          return fields.any(
            (field) => _string(item[field]).toLowerCase().contains(_search),
          );
        })
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _maps(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  String _string(dynamic value, [String fallback = '']) =>
      value?.toString() ?? fallback;

  String _pretty(dynamic value) {
    if (value == null) return 'Sin información disponible.';
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      return value.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }
    return value.toString();
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    bool number = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(
      controller: controller,
      keyboardType: number
          ? const TextInputType.numberWithOptions(decimal: true, signed: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (required && text.isEmpty) return 'Este campo es obligatorio';
        if (number && text.isNotEmpty && double.tryParse(text) == null) {
          return 'Ingresa un número válido';
        }
        return null;
      },
    ),
  );

  Future<bool?> _confirm(BuildContext context, String message) =>
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

  void _notify(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AdminChat extends StatefulWidget {
  const _AdminChat({required this.api});

  final ApiClient api;

  @override
  State<_AdminChat> createState() => _AdminChatState();
}

class _AdminChatState extends State<_AdminChat> {
  final _controller = TextEditingController();
  final _messages = <(bool, String)>[
    (false, 'Hola. Puedo ayudarte a consultar los incidentes y las zonas.'),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    _controller.clear();
    setState(() {
      _sending = true;
      _messages.add((true, text));
    });
    try {
      final response = await widget.api.post('Ai/Chat', {'message': text});
      if (!mounted) return;
      setState(() => _messages.add((false, _responseText(response))));
    } on Exception catch (error) {
      if (!mounted) return;
      setState(
        () =>
            _messages.add((false, 'No se pudo completar la consulta: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _responseText(dynamic response) {
    if (response is String) return response;
    if (response is Map<String, dynamic>) {
      return (response['response'] ?? response['message'] ?? response['reply'])
              ?.toString() ??
          response.toString();
    }
    return response?.toString() ?? 'La API no devolvió una respuesta.';
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Asistente administrativo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          for (final message in _messages)
            Align(
              alignment: message.$1
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 680),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: message.$1
                      ? AppColors.blue.withValues(alpha: 0.1)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SelectableText(message.$2),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !_sending,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    labelText: 'Pregunta sobre el sistema',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Enviar',
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _AdminClassifier extends StatefulWidget {
  const _AdminClassifier({required this.api});

  final ApiClient api;

  @override
  State<_AdminClassifier> createState() => _AdminClassifierState();
}

class _AdminClassifierState extends State<_AdminClassifier> {
  final _description = TextEditingController();
  bool _loading = false;
  String? _result;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _classify() async {
    final description = _description.text.trim();
    if (description.isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    try {
      final response = await widget.api.post('Ai/Classify', {
        'description': description,
      });
      if (!mounted) return;
      setState(() => _result = response.toString());
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _result = 'No se pudo clasificar: $error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Clasificar incidente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Descripción del incidente',
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _loading ? null : _classify,
              child: Text(_loading ? 'Analizando…' : 'Clasificar'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 8),
            SelectableText(_result!),
          ],
        ],
      ),
    ),
  );
}

class _CommentsDialog extends StatefulWidget {
  const _CommentsDialog({required this.api, required this.incidentId});

  final ApiClient api;
  final String incidentId;

  @override
  State<_CommentsDialog> createState() => _CommentsDialogState();
}

class _CommentsDialogState extends State<_CommentsDialog> {
  final _content = TextEditingController();
  late Future<dynamic> _comments;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _comments = widget.api.get('Incidents/${widget.incidentId}/Comments/All');
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _content.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.api.post('Incidents/${widget.incidentId}/Comments', {
        'content': text,
        'isInternal': true,
      });
      if (!mounted) return;
      _content.clear();
      setState(() {
        _comments = widget.api.get(
          'Incidents/${widget.incidentId}/Comments/All',
        );
      });
    } on Exception catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el comentario: $error')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Comentarios del incidente'),
    content: SizedBox(
      width: 540,
      height: 420,
      child: Column(
        children: [
          Expanded(
            child: FutureBuilder<dynamic>(
              future: _comments,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'No se pudieron cargar los comentarios: ${snapshot.error}',
                    ),
                  );
                }
                final comments = snapshot.data is List
                    ? (snapshot.data as List)
                    : const [];
                if (comments.isEmpty) {
                  return const Center(child: Text('No hay comentarios.'));
                }
                return ListView(
                  children: [
                    for (final item
                        in comments.whereType<Map<String, dynamic>>())
                      ListTile(
                        title: Text(item['content']?.toString() ?? ''),
                        subtitle: Text(
                          '${item['username'] ?? item['author'] ?? ''} · ${item['createdAt'] ?? ''}',
                        ),
                        trailing: item['isInternal'] == true
                            ? const Chip(label: Text('Interno'))
                            : null,
                      ),
                  ],
                );
              },
            ),
          ),
          TextField(
            controller: _content,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Nuevo comentario'),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cerrar'),
      ),
      FilledButton(
        onPressed: _sending ? null : _send,
        child: const Text('Enviar'),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(36),
    child: Center(child: Text(message)),
  );
}

const _statuses = ['PENDING', 'IN_PROGRESS', 'RESOLVED', 'REJECTED'];
const _priorities = ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'];
const _risks = ['LOW', 'MODERATE', 'HIGH', 'CRITICAL'];

String _statusLabel(String status) => switch (status) {
  'PENDING' => 'Pendiente',
  'IN_PROGRESS' => 'En proceso',
  'RESOLVED' => 'Resuelto',
  'REJECTED' => 'Rechazado',
  _ => status,
};
