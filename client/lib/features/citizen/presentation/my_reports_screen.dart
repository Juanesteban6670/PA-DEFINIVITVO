import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/incident_repository.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/core/data/report_draft_store.dart';
import 'package:cartagena_segura/shared/responsive_layout.dart';
import 'package:cartagena_segura/shared/skeleton_loader.dart';
import 'package:cartagena_segura/shared/theme.dart';

import 'report_screen.dart';

/// Pantalla 04 · Reportes
/// Basada fielmente en Figma (Node 2:15).
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
  int _selectedTab = 1; // 0 = Comunidad, 1 = Mis reportes
  String _selectedStatusFilter = 'Todos'; // 'Todos', 'En revisión', 'En atención', 'Resueltos'
  
  late Future<List<Incident>> _incidents;
  late Future<List<ReportDraft>> _pending;
  String? _openedInitialIncidentId;

  @override
  void initState() {
    super.initState();
    widget.incidentRefresh.addListener(_reload);
    _incidents = _loadCurrentList();
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

  Future<List<Incident>> _loadCurrentList() {
    return loadIncidents(widget.api, mine: _selectedTab == 1);
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _incidents = _loadCurrentList();
        _pending = widget.drafts.readPending();
      });
    }
  }

  void _onTabChanged(int index) {
    if (_selectedTab != index) {
      setState(() {
        _selectedTab = index;
        _incidents = _loadCurrentList();
      });
    }
  }

  Future<void> _openReportForm() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReportScreen(
          api: widget.api,
          drafts: widget.drafts,
          onReportSubmitted: () {
            widget.onReportSubmitted();
            _reload();
          },
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
          const SnackBar(content: Text('Reporte pendiente enviado con éxito')),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reenviar: $error')),
        );
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
          SnackBar(content: Text('No se pudo borrar el borrador: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: Breakpoints.maxContentWidth,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(mobile: 16.0, tablet: 24.0, desktop: 32.0),
            vertical: 16.0,
          ),
          child: FutureBuilder<List<Incident>>(
            future: _incidents,
            builder: (context, snapshot) {
              final allIncidents = snapshot.data ?? const <Incident>[];
              _openInitialIncidentIfAvailable(context, allIncidents);

              // Filtrado por estado
              final filtered = allIncidents.where((item) {
                if (_selectedStatusFilter == 'Todos') return true;
                if (_selectedStatusFilter == 'En revisión') {
                  return item.status.toUpperCase() == 'PENDING';
                }
                if (_selectedStatusFilter == 'En atención') {
                  return item.status.toUpperCase() == 'IN_PROGRESS';
                }
                if (_selectedStatusFilter == 'Resueltos') {
                  return item.status.toUpperCase() == 'RESOLVED';
                }
                return true;
              }).toList();

              final isWide = context.isWide;

              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  // 1. TÍTULO, SUBTÍTULO Y ACCIONES ADAPTATIVAS
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reportes de Seguridad',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tu voz ayuda a cuidar Cartagena. Monitoreo colaborativo en tiempo real.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F4C81),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _openReportForm,
                          icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
                          label: const Text(
                            'Crear nuevo reporte',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Text(
                      'Reportes',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Tu voz ayuda a cuidar Cartagena.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C81),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _openReportForm,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Crear nuevo reporte',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // 2. CONTROLES: Segmented toggle + Chips de estado
                  if (isWide)
                    Row(
                      children: [
                        SizedBox(
                          width: 280,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : const Color(0xFFEEF2F6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SegmentItem(
                                    label: 'Comunidad',
                                    selected: _selectedTab == 0,
                                    onTap: () => _onTabChanged(0),
                                  ),
                                ),
                                Expanded(
                                  child: _SegmentItem(
                                    label: 'Mis reportes',
                                    selected: _selectedTab == 1,
                                    onTap: () => _onTabChanged(1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final status in const [
                                  'Todos',
                                  'En revisión',
                                  'En atención',
                                  'Resueltos',
                                ]) ...[
                                  _StatusFilterPill(
                                    label: status,
                                    selected: _selectedStatusFilter == status,
                                    onTap: () => setState(() => _selectedStatusFilter = status),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${allIncidents.length} reportes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : const Color(0xFFEEF2F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SegmentItem(
                              label: 'Comunidad',
                              selected: _selectedTab == 0,
                              onTap: () => _onTabChanged(0),
                            ),
                          ),
                          Expanded(
                            child: _SegmentItem(
                              label: 'Mis reportes',
                              selected: _selectedTab == 1,
                              onTap: () => _onTabChanged(1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedTab == 0 ? 'Cerca de ti' : 'Mis reportes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                          ),
                        ),
                        Text(
                          '${allIncidents.length} activos',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final status in const [
                            'Todos',
                            'En revisión',
                            'En atención',
                            'Resueltos',
                          ]) ...[
                            _StatusFilterPill(
                              label: status,
                              selected: _selectedStatusFilter == status,
                              onTap: () => setState(() => _selectedStatusFilter = status),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // ESTADOS DE CARGA / LISTADO
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Column(
                      children: [
                        SkeletonIncidentCard(),
                        SizedBox(height: 10),
                        SkeletonIncidentCard(),
                        SizedBox(height: 10),
                        SkeletonIncidentCard(),
                      ],
                    )
                  else if (snapshot.hasError)
                    _ReportsError(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    )
                  else if (filtered.isEmpty)
                    _EmptyReports(
                      isMyReports: _selectedTab == 1,
                      onCreate: _openReportForm,
                    )
                  else
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final cols = availableWidth >= 1100 ? 3 : (availableWidth >= 680 ? 2 : 1);
                        if (cols == 1) {
                          return Column(
                            children: [
                              for (final incident in filtered)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _FigmaReportCard(
                                    incident: incident,
                                    onTap: () => _showDetails(incident),
                                  ),
                                ),
                            ],
                          );
                        }
                        const spacing = 16.0;
                        final cardWidth = (availableWidth - (spacing * (cols - 1))) / cols;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final incident in filtered)
                              SizedBox(
                                width: cardWidth,
                                child: _FigmaReportCard(
                                  incident: incident,
                                  onTap: () => _showDetails(incident),
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                  // Reportes pendientes en almacenamiento local (si está en Mis reportes)
                  if (_selectedTab == 1)
                    FutureBuilder<List<ReportDraft>>(
                      future: _pending,
                      builder: (context, pendingSnapshot) {
                        final pending = pendingSnapshot.data ?? const <ReportDraft>[];
                        if (pending.isEmpty) return const SizedBox.shrink();
                        return _PendingReports(
                          drafts: pending,
                          onRetry: _retryPending,
                          onDelete: _deletePending,
                        );
                      },
                    ),

                    const SizedBox(height: 18),

                    // 5. BANNER INFORMATIVO (Figma 04): "Una comunidad que se cuida"
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            color: isDark ? AppColors.sky : const Color(0xFF0F4C81),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Una comunidad que se cuida',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Reporta con respeto. No compartas datos personales.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ),
        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWide = context.isWide;

    if (isWide) {
      showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          incident.type,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: _buildDetailsBody(incident, isDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  incident.type,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                  ),
                ),
                const SizedBox(height: 10),
                _buildDetailsBody(incident, isDark),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDetailsBody(Incident incident, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _StatusBadge(status: incident.status, isDark: isDark),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Prioridad: ${incident.priority}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextMuted : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          incident.description.isEmpty ? 'Sin descripción' : incident.description,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppColors.darkText : const Color(0xFF334155),
            height: 1.5,
          ),
        ),
        if (incident.location.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  incident.location,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (incident.createdAt != null) ...[
          const SizedBox(height: 12),
          Text(
            'Enviado: ${_formatDate(incident.createdAt!)}',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
        if (incident.latitude != null && incident.longitude != null) ...[
          const SizedBox(height: 8),
          Text(
            'GPS: ${incident.latitude}, ${incident.longitude}',
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

// ==========================================
// COMPONENTES ESTILO FIGMA 04
// ==========================================

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.brightBlue : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}

class _StatusFilterPill extends StatelessWidget {
  const _StatusFilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.brightBlue : const Color(0xFF0F4C81))
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? (isDark ? AppColors.brightBlue : const Color(0xFF0F4C81))
                : (isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? Colors.white
                : (isDark ? AppColors.darkTextMuted : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }
}

class _FigmaReportCard extends StatelessWidget {
  const _FigmaReportCard({
    required this.incident,
    required this.onTap,
  });

  final Incident incident;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (categoryName, iconData, iconColor, iconBg) = _categoryInfo(incident.type, isDark);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícono de categoría con su tinte
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Contenido central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoría y distancia opcional
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: iconColor,
                        ),
                      ),
                      Text(
                        'a 450 m',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Título / Descripción
                  Text(
                    incident.description.isNotEmpty ? incident.description : incident.type,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Ubicación y tiempo relativo
                  Text(
                    '${incident.location.isNotEmpty ? incident.location : "Cartagena"} · ${_formatRelativeTime(incident.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Badge de estado
                  _StatusBadge(status: incident.status, isDark: isDark),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkTextMuted : const Color(0xFFCBD5E1),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  (String, IconData, Color, Color) _categoryInfo(String type, bool isDark) {
    final lower = type.toLowerCase();
    if (lower.contains('traf') || lower.contains('movil') || lower.contains('accidente')) {
      return (
        'Tráfico',
        Icons.directions_car_rounded,
        isDark ? const Color(0xFFFBBF24) : const Color(0xFF9A6200),
        isDark ? const Color(0xFF451A03) : const Color(0xFFFFF4DC),
      );
    }
    if (lower.contains('segur') || lower.contains('robo') || lower.contains('sospech')) {
      return (
        'Seguridad',
        Icons.shield_outlined,
        isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
        isDark ? const Color(0xFF450A0A) : const Color(0xFFFEE2E2),
      );
    }
    if (lower.contains('vía') || lower.contains('via') || lower.contains('calle') || lower.contains('obra')) {
      return (
        'Vía cerrada',
        Icons.construction_rounded,
        isDark ? const Color(0xFF34D399) : const Color(0xFF087554),
        isDark ? const Color(0xFF064E3B) : const Color(0xFFE6F7EF),
      );
    }
    if (lower.contains('alumbr') || lower.contains('luz') || lower.contains('lumin')) {
      return (
        'Servicios',
        Icons.lightbulb_outline_rounded,
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F4C81),
        isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE7F0F8),
      );
    }
    return (
      'Incidente',
      Icons.warning_amber_rounded,
      isDark ? const Color(0xFF60A5FA) : const Color(0xFF0F4C81),
      isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE7F0F8),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, this.isDark});

  final String status;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveIsDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final (label, bg, fg) = switch (status.toUpperCase()) {
      'RESOLVED' => (
          'Resuelto',
          effectiveIsDark ? const Color(0xFF064E3B) : const Color(0xFFE6F7EF),
          effectiveIsDark ? const Color(0xFF6EE7B7) : const Color(0xFF087554),
        ),
      'IN_PROGRESS' => (
          'En atención',
          effectiveIsDark ? const Color(0xFF451A03) : const Color(0xFFFFF4DC),
          effectiveIsDark ? const Color(0xFFFBBF24) : const Color(0xFF9A6200),
        ),
      _ => (
          'En revisión',
          effectiveIsDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          effectiveIsDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: effectiveIsDark ? fg.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _EmptyReports extends StatelessWidget {
  const _EmptyReports({required this.isMyReports, required this.onCreate});

  final bool isMyReports;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE7F0F8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.assignment_outlined,
              size: 28,
              color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isMyReports ? 'No has creado reportes aún' : 'No hay reportes en esta categoría',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: isDark ? AppColors.darkText : const Color(0xFF142C40),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tu participación es fundamental para mantener a Cartagena segura e informada.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C81),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: onCreate,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Crear reporte'),
          ),
        ],
      ),
    );
  }
}

class _ReportsError extends StatelessWidget {
  const _ReportsError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAuthError = message.contains('401') ||
        message.contains('403') ||
        message.toLowerCase().contains('sesión') ||
        message.toLowerCase().contains('autentic');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Icon(
            isAuthError ? Icons.lock_outline_rounded : Icons.cloud_off_outlined,
            color: isAuthError
                ? (isDark ? AppColors.brightBlue : const Color(0xFF0F4C81))
                : const Color(0xFFDC2626),
            size: 36,
          ),
          const SizedBox(height: 10),
          Text(
            isAuthError
                ? 'Sesión requerida'
                : 'No se pudieron cargar los reportes',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : const Color(0xFF142C40),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isAuthError
                ? 'Para consultar tus reportes personales debes iniciar sesión con tu cuenta.'
                : message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isAuthError) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C81),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (GoRouter.maybeOf(context) != null) {
                      context.go('/Login');
                    }
                  },
                  icon: const Icon(Icons.login_rounded, size: 16),
                  label: const Text('Iniciar sesión'),
                ),
                const SizedBox(width: 10),
              ],
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Pendientes de enviar (${drafts.length})',
          style: TextStyle(
            color: isDark ? AppColors.darkText : const Color(0xFF142C40),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        for (final draft in drafts)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
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
                  Icons.cloud_upload_outlined,
                  color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        draft.type,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark ? AppColors.darkText : const Color(0xFF142C40),
                        ),
                      ),
                      Text(
                        draft.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.darkTextMuted : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Reintentar envío',
                  onPressed: () => onRetry(draft),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 20,
                    color: isDark ? AppColors.brightBlue : const Color(0xFF0F4C81),
                  ),
                ),
                IconButton(
                  tooltip: 'Eliminar borrador',
                  onPressed: () => onDelete(draft),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _formatDate(DateTime value) {
  final date = value.toLocal();
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/${date.year} · $hour:$minute';
}

String _formatRelativeTime(DateTime? date) {
  if (date == null) return 'Reciente';
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 60) {
    return 'Hace ${diff.inMinutes.clamp(1, 59)} min';
  } else if (diff.inHours < 24) {
    return 'Hace ${diff.inHours} h';
  } else {
    return 'Hace ${diff.inDays} d';
  }
}
