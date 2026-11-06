import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/report_draft_store.dart';
import 'package:cartagena_segura/shared/theme.dart';
import 'report_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({
    required this.api,
    required this.drafts,
    required this.incidentRefresh,
    required this.onReportSubmitted,
    this.initialIncidentId,
    super.key,
  });

  final ApiClient api;
  final ReportDraftStore drafts;
  final ValueNotifier<int> incidentRefresh;
  final VoidCallback onReportSubmitted;
  final String? initialIncidentId;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Future<List<Incident>> _incidents;
  late Future<List<ReportDraft>> _pending;
  String? _openedInitialIncidentId;

  @override
  void initState() {
    super.initState();
    widget.incidentRefresh.addListener(_reload);
    _incidents = loadIncidents(widget.api, mine: true);
    _pending = widget.drafts.readPending();
  }

  @override
  void didUpdateWidget(covariant MyReportsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.incidentRefresh != widget.incidentRefresh) {
      oldWidget.incidentRefresh.removeListener(_reload);
      widget.incidentRefresh.addListener(_reload);
    }
  }

  @override
  void dispose() {
    widget.incidentRefresh.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _incidents = loadIncidents(widget.api, mine: true);
        _pending = widget.drafts.readPending();
      });
    }
  }

  Future<void> _openReportForm() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReportScreen(
          api: widget.api,
          drafts: widget.drafts,
          onReportSubmitted: widget.onReportSubmitted,
        ),
      ),
    );
  }

  Future<void> _retryPending(ReportDraft draft) async {
    try {
      await submitReportDraft(
        widget.api,
        draft,
        onImagesUploaded: widget.drafts.updatePending,
      );
      await deleteReportPhotos(draft.photoPaths);
      await widget.drafts.removePending(draft.idempotencyKey);
      widget.onReportSubmitted();
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reporte pendiente enviado')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('No se pudo reenviar: $error')));
      }
    }
  }

  Future<void> _deletePending(ReportDraft draft) async {
    try {
      await deleteReportPhotos(draft.photoPaths);
      await widget.drafts.removePending(draft.idempotencyKey);
      _reload();
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No se pudo borrar el envío pendiente: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Incident>>(
      future: _incidents,
      builder: (context, snapshot) {
        final incidents = snapshot.data ?? const <Incident>[];
        _openInitialIncidentIfAvailable(context, incidents);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mis reportes',
                        style: TextStyle(
                          color: AppColors.navy,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Consulta el estado de tus casos',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar reportes',
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh),
                ),
                FilledButton.icon(
                  onPressed: _openReportForm,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nuevo'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 52),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (snapshot.hasError)
              _ReportsError(
                message: snapshot.error.toString(),
                onRetry: _reload,
              )
            else if (incidents.isEmpty)
              _EmptyReports(onCreate: _openReportForm)
            else ...[
              _ReportsSummary(incidents: incidents),
              const SizedBox(height: 16),
              for (final incident in incidents)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _IncidentCard(
                    incident: incident,
                    onTap: () => _showDetails(incident),
                  ),
                ),
            ],
            FutureBuilder<List<ReportDraft>>(
              future: _pending,
              builder: (context, pendingSnapshot) {
                final pending = pendingSnapshot.data ?? const <ReportDraft>[];
                if (pendingSnapshot.hasError) {
                  return _ReportsError(
                    message: pendingSnapshot.error.toString(),
                    onRetry: _reload,
                  );
                }
                if (pending.isEmpty) return const SizedBox.shrink();
                return _PendingReports(
                  drafts: pending,
                  onRetry: _retryPending,
                  onDelete: _deletePending,
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _openInitialIncidentIfAvailable(
    BuildContext context,
    List<Incident> incidents,
  ) {
    final id = widget.initialIncidentId;
    if (id == null || id.isEmpty || _openedInitialIncidentId == id) return;
    final incident = incidents.where((item) => item.id == id).firstOrNull;
    if (incident == null) return;
    _openedInitialIncidentId = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.mounted) _showDetails(incident);
    });
  }

  void _showDetails(Incident incident) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                incident.type,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _StatusChip(value: incident.status, priority: false),
                  _StatusChip(value: incident.priority, priority: true),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                incident.description.isEmpty
                    ? 'Sin descripción'
                    : incident.description,
              ),
              if (incident.location.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place_outlined, color: AppColors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(incident.location)),
                  ],
                ),
              ],
              if (incident.createdAt != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Enviado: ${_formatDate(incident.createdAt!)}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
              if (incident.latitude != null && incident.longitude != null) ...[
                const SizedBox(height: 8),
                Text(
                  'GPS: ${incident.latitude}, ${incident.longitude}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportsSummary extends StatelessWidget {
  const _ReportsSummary({required this.incidents});

  final List<Incident> incidents;

  @override
  Widget build(BuildContext context) {
    final pending = incidents.where((item) => item.status == 'PENDING').length;
    final active = incidents
        .where((item) => item.status == 'IN_PROGRESS')
        .length;
    final resolved = incidents
        .where((item) => item.status == 'RESOLVED')
        .length;
    return Row(
      children: [
        _SummaryPill(label: '$pending pendientes', color: AppColors.amber),
        const SizedBox(width: 7),
        _SummaryPill(label: '$active en progreso', color: AppColors.blue),
        const SizedBox(width: 7),
        _SummaryPill(label: '$resolved resueltos', color: AppColors.green),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.blue.withValues(alpha: 0.08),
                foregroundColor: AppColors.blue,
                child: const Icon(Icons.warning_amber_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      incident.location.isEmpty
                          ? incident.description
                          : incident.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                    ),
                    if (incident.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(incident.createdAt!),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 7),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(value: incident.status, priority: false),
                  const SizedBox(height: 5),
                  _StatusChip(value: incident.priority, priority: true),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.value, required this.priority});

  final String value;
  final bool priority;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch ((priority, value)) {
      (false, 'PENDING') => ('Pendiente', AppColors.amber),
      (false, 'IN_PROGRESS') => ('En progreso', AppColors.blue),
      (false, 'RESOLVED') => ('Resuelto', AppColors.green),
      (false, 'REJECTED') => ('Rechazado', AppColors.red),
      (true, 'LOW') => ('Baja', AppColors.green),
      (true, 'MEDIUM') => ('Media', AppColors.amber),
      (true, 'HIGH') => ('Alta', const Color(0xFFF97316)),
      (true, 'CRITICAL') => ('Crítica', AppColors.red),
      _ => (value, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.assignment_outlined,
            size: 42,
            color: AppColors.muted,
          ),
          const SizedBox(height: 10),
          const Text(
            'Todavía no tienes reportes',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'Si observas una situación, compártela con Cartagena Segura.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Crear reporte'),
          ),
        ],
      ),
    ),
  );
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.muted,
            size: 38,
          ),
          const SizedBox(height: 10),
          const Text(
            'No se pudieron cargar tus reportes',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    ),
  );
}

class _PendingReports extends StatelessWidget {
  const _PendingReports({
    required this.drafts,
    required this.onRetry,
    required this.onDelete,
  });

  final List<ReportDraft> drafts;
  final ValueChanged<ReportDraft> onRetry;
  final ValueChanged<ReportDraft> onDelete;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      Text(
        'Pendientes de enviar (${drafts.length})',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      for (final draft in drafts)
        Card(
          child: ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: Text(draft.type),
            subtitle: Text(
              draft.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                IconButton(
                  tooltip: 'Reintentar envío',
                  onPressed: () => onRetry(draft),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Eliminar envío pendiente',
                  onPressed: () => onDelete(draft),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}

String _formatDate(DateTime value) {
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} · $hour:$minute';
}
