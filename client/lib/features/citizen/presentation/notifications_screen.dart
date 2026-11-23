import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/features/citizen/presentation/widgets/incident_compact_card.dart';
import 'package:cartagena_segura/shared/responsive_layout.dart';
import 'package:cartagena_segura/shared/theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    required this.api,
    this.isAdmin = false,
    super.key,
  });

  final ApiClient api;
  final bool isAdmin;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _notifications;
  bool _updating = false;
  String _selectedFilter =
      'Todas'; // 'Todas', 'No leídas', 'Con fotos', 'Resueltos'

  @override
  void initState() {
    super.initState();
    _notifications = _load();
  }

  Future<List<AppNotification>> _load() async {
    final response = await widget.api.get('Notifications');
    if (response is! List) {
      throw const FormatException('La API devolvió notificaciones inválidas');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  void _reload() => setState(() => _notifications = _load());

  Future<void> _markRead(AppNotification notification) async {
    if (notification.read || _updating) return;
    setState(() => _updating = true);
    try {
      await widget.api.patch('Notifications/${notification.id}/Read');
      _reload();
    } on Exception catch (error) {
      _showMessage('No se pudo marcar como leída: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _open(AppNotification notification) async {
    if (!notification.read) await _markRead(notification);
    final incidentId = notification.relatedEntityId;
    if (!mounted || incidentId == null || incidentId.isEmpty) return;

    final route = widget.isAdmin ? '/Admin/Incidents' : '/App/Incidents';
    final destination = Uri(
      path: route,
      queryParameters: {'id': incidentId},
    ).toString();

    if (GoRouter.maybeOf(context) != null) {
      context.go(destination);
    }
  }

  Future<void> _markAllRead() async {
    setState(() => _updating = true);
    try {
      await widget.api.patch('Notifications/ReadAll');
      _reload();
    } on Exception catch (error) {
      _showMessage('No se pudieron actualizar las notificaciones: $error');
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _delete(AppNotification notification) async {
    try {
      await widget.api.delete('Notifications/${notification.id}');
      _reload();
    } on Exception catch (error) {
      _showMessage('No se pudo eliminar la notificación: $error');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  List<AppNotification> _filterNotifications(List<AppNotification> all) {
    switch (_selectedFilter) {
      case 'No leídas':
        return all.where((n) => !n.read).toList();
      case 'Con fotos':
        return all.where((n) => n.hasPhotos).toList();
      case 'Resueltos':
        return all
            .where(
              (n) =>
                  n.incidentStatus?.toUpperCase() == 'RESOLVED' ||
                  n.type.contains('RESOLVED') ||
                  n.title.toLowerCase().contains('resuelto'),
            )
            .toList();
      case 'Todas':
      default:
        return all;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Reciente';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  (String, Color, Color) _getStatusBadge(String? status, bool isDark) {
    switch (status?.toUpperCase()) {
      case 'RESOLVED':
        return (
          'Resuelto',
          isDark ? AppColors.darkGreen : AppColors.green,
          (isDark ? AppColors.darkGreen : AppColors.green).withValues(
            alpha: 0.15,
          ),
        );
      case 'IN_PROGRESS':
        return (
          'En atención',
          isDark ? AppColors.brightBlue : AppColors.blue,
          (isDark ? AppColors.brightBlue : AppColors.blue).withValues(
            alpha: 0.15,
          ),
        );
      case 'REJECTED':
        return (
          'Rechazado',
          isDark ? AppColors.darkRed : AppColors.red,
          (isDark ? AppColors.darkRed : AppColors.red).withValues(alpha: 0.15),
        );
      case 'PENDING':
      default:
        return (
          'Pendiente / Nuevo',
          isDark ? AppColors.darkAmber : AppColors.amber,
          (isDark ? AppColors.darkAmber : AppColors.amber).withValues(
            alpha: 0.15,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.canvas,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkCanvas : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? AppColors.darkText : AppColors.navy,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(widget.isAdmin ? '/Admin' : '/App');
            }
          },
        ),
        title: Row(
          children: [
            Text(
              widget.isAdmin ? 'Alertas de Administrador' : 'Notificaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkText : AppColors.navy,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _updating ? null : _markAllRead,
            icon: Icon(
              Icons.done_all_rounded,
              size: 18,
              color: isDark ? AppColors.brightBlue : AppColors.blue,
            ),
            label: Text(
              'Leer todas',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.brightBlue : AppColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveContent(
          maxWidth: Breakpoints.maxContentWidth,
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              mobile: 16.0,
              tablet: 24.0,
              desktop: 32.0,
            ),
            vertical: 14.0,
          ),
          child: FutureBuilder<List<AppNotification>>(
            future: _notifications,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 40,
                          color: isDark ? AppColors.darkRed : AppColors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No se pudieron cargar las notificaciones',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkText : AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _reload,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final all = snapshot.data ?? const <AppNotification>[];
              final unreadCount = all.where((n) => !n.read).length;
              final filtered = _filterNotifications(all);

              return RefreshIndicator(
                color: isDark ? AppColors.brightBlue : AppColors.blue,
                backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                onRefresh: () async => _reload(),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    // Filtros rápidos horizontales
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in [
                            'Todas',
                            'No leídas',
                            'Con fotos',
                            'Resueltos',
                          ]) ...[
                            _buildFilterChip(
                              label: f == 'No leídas' && unreadCount > 0
                                  ? '$f ($unreadCount)'
                                  : f,
                              isSelected: _selectedFilter == f,
                              onTap: () => setState(() => _selectedFilter = f),
                              isDark: isDark,
                              hasBadge: f == 'No leídas' && unreadCount > 0,
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Contador y estado
                    Row(
                      children: [
                        Text(
                          '${filtered.length} notificaciones ${unreadCount > 0 ? "· $unreadCount sin leer" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (filtered.isEmpty)
                      _buildEmptyState(isDark)
                    else
                      for (final n in filtered)
                        _buildNotificationCard(n, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    bool hasBadge = false,
  }) {
    final activeBg = isDark ? AppColors.brightBlue : AppColors.blue;
    final inactiveBg = isDark ? AppColors.darkCard : Colors.white;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? activeBg
                : (isDark ? AppColors.darkBorder : AppColors.border),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBadge && !isSelected) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.brightBlue : AppColors.blue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkText : AppColors.navy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification n, bool isDark) {
    final (catName, catColor, catBg, catIcon) =
        IncidentCompactCard.getCategoryMeta(n.category ?? n.type, isDark);
    final (statusLabel, statusColor, statusBg) = _getStatusBadge(
      n.incidentStatus,
      isDark,
    );
    final hasIncident =
        n.relatedEntityId != null && n.relatedEntityId!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: !n.read
            ? (isDark ? const Color(0xFF132238) : const Color(0xFFF0F6FF))
            : (isDark ? AppColors.darkCard : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: !n.read
              ? (isDark
                    ? AppColors.brightBlue.withValues(alpha: 0.4)
                    : AppColors.blue.withValues(alpha: 0.3))
              : (isDark ? AppColors.darkBorder : AppColors.border),
          width: !n.read ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: Icono, Estado no leído, Categoría y Fecha
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(catIcon, color: catColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!n.read) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.brightBlue
                                    : AppColors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              n.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: !n.read
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.navy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(n.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chip de estado del incidente
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Mensaje detallado
            Text(
              n.message,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark ? AppColors.darkText : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 10),

            // Metadatos adicionales: Ubicación, Reportante y Evidencias
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (n.location != null && n.location!.isNotEmpty)
                  _buildMetaTag(
                    icon: Icons.location_on_outlined,
                    label: n.location!,
                    isDark: isDark,
                  ),
                if (n.reportedBy != null && n.reportedBy!.isNotEmpty)
                  _buildMetaTag(
                    icon: Icons.person_outline_rounded,
                    label: 'Reportó: @${n.reportedBy!}',
                    isDark: isDark,
                  ),
                if (n.hasPhotos)
                  _buildMetaTag(
                    icon: Icons.photo_camera_rounded,
                    label: 'Con evidencia fotográfica',
                    isDark: isDark,
                    color: isDark ? AppColors.brightBlue : AppColors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Botones de acción
            Row(
              children: [
                if (hasIncident)
                  ElevatedButton.icon(
                    onPressed: () => _open(n),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text(
                      'Ver incidente',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark
                          ? AppColors.brightBlue
                          : AppColors.blue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                const Spacer(),
                if (!n.read)
                  IconButton(
                    tooltip: 'Marcar como leída',
                    onPressed: () => _markRead(n),
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 20,
                      color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                    ),
                  ),
                IconButton(
                  tooltip: 'Eliminar notificación',
                  onPressed: () => _delete(n),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaTag({
    required IconData icon,
    required String label,
    required bool isDark,
    Color? color,
  }) {
    final textColor =
        color ?? (isDark ? AppColors.darkTextMuted : AppColors.muted);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardHover : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 40,
            color: isDark ? AppColors.darkTextMuted : AppColors.muted,
          ),
          const SizedBox(height: 12),
          Text(
            'Bandeja al día',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No hay notificaciones pendientes en este momento.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
