import 'package:cartagena_segura/shared/evidence_image.dart';
import 'package:flutter/material.dart';
import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/core/data/models.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Tarjeta moderna, compacta y visualmente organizada para reportes recientes.
class IncidentCompactCard extends StatelessWidget {
  const IncidentCompactCard({
    required this.incident,
    required this.isDark,
    this.onTap,
    super.key,
  });

  final Incident incident;
  final bool isDark;
  final VoidCallback? onTap;

  static String formatTimeAgo(DateTime? date) {
    if (date == null) return 'Reciente';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes <= 0 ? 1 : diff.inMinutes;
      return 'Hace $mins min';
    }
    if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} h';
    }
    if (diff.inDays == 1) {
      return 'Ayer';
    }
    return 'Hace ${diff.inDays} d';
  }

  static (String, Color, Color, IconData) getCategoryMeta(
    String type,
    bool isDark,
  ) {
    final t = type.toUpperCase();
    if (t.contains('TRAF') ||
        t.contains('TRANSIT') ||
        t.contains('CONGESTION') ||
        t.contains('VIA')) {
      return (
        'Tráfico',
        isDark ? AppColors.darkAmber : AppColors.amber,
        (isDark ? AppColors.darkAmber : AppColors.amber).withValues(
          alpha: isDark ? 0.2 : 0.12,
        ),
        Icons.directions_car_rounded,
      );
    }
    if (t.contains('ROBO') ||
        t.contains('HURTO') ||
        t.contains('SEGURIDAD') ||
        t.contains('SOS') ||
        t.contains('PELEA') ||
        t.contains('ALTERCADO') ||
        t.contains('PANICO')) {
      return (
        'Seguridad',
        isDark ? AppColors.darkRed : AppColors.red,
        (isDark ? AppColors.darkRed : AppColors.red).withValues(
          alpha: isDark ? 0.2 : 0.12,
        ),
        Icons.shield_rounded,
      );
    }
    if (t.contains('ALUMBRADO') ||
        t.contains('HUECO') ||
        t.contains('BASURA') ||
        t.contains('INFRAESTRUCTURA') ||
        t.contains('AGUA') ||
        t.contains('POSTE')) {
      return (
        'Servicios',
        isDark ? AppColors.sky : AppColors.blue,
        (isDark ? AppColors.sky : AppColors.blue).withValues(
          alpha: isDark ? 0.2 : 0.12,
        ),
        Icons.build_circle_rounded,
      );
    }
    return (
      'Incidente',
      isDark ? AppColors.darkPurple : AppColors.purple,
      (isDark ? AppColors.darkPurple : AppColors.purple).withValues(
        alpha: isDark ? 0.2 : 0.12,
      ),
      Icons.warning_amber_rounded,
    );
  }

  static (String, Color, Color) getStatusMeta(String status, bool isDark) {
    switch (status.toUpperCase()) {
      case 'RESOLVED':
        return (
          'Resuelto',
          isDark ? AppColors.darkGreen : AppColors.green,
          (isDark ? AppColors.darkGreen : AppColors.green).withValues(
            alpha: isDark ? 0.22 : 0.12,
          ),
        );
      case 'IN_PROGRESS':
        return (
          'En atención',
          isDark ? AppColors.brightBlue : AppColors.blue,
          (isDark ? AppColors.brightBlue : AppColors.blue).withValues(
            alpha: isDark ? 0.22 : 0.12,
          ),
        );
      case 'REJECTED':
        return (
          'Desestimado',
          isDark ? AppColors.darkTextMuted : AppColors.muted,
          (isDark ? AppColors.darkTextMuted : AppColors.muted).withValues(
            alpha: 0.15,
          ),
        );
      case 'PENDING':
      default:
        return (
          'En revisión',
          isDark ? AppColors.darkAmber : AppColors.amber,
          (isDark ? AppColors.darkAmber : AppColors.amber).withValues(
            alpha: isDark ? 0.22 : 0.12,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (catName, catColor, catBg, catIcon) = getCategoryMeta(
      incident.type,
      isDark,
    );
    final (statusLabel, statusColor, statusBg) = getStatusMeta(
      incident.status,
      isDark,
    );
    final timeAgo = formatTimeAgo(incident.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icono de categoría
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: catBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Contenido central (tipo, ubicación, descripción)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              incident.description.isNotEmpty
                                  ? incident.description
                                  : incident.type,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.darkText
                                    : AppColors.navy,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (incident.imageUrls.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.photo_camera_rounded,
                              size: 13,
                              color: isDark
                                  ? AppColors.brightBlue
                                  : AppColors.blue,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 12,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.muted,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${incident.location.isNotEmpty ? incident.location : "Cartagena"} · $timeAgo',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.darkTextMuted
                                    : AppColors.muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Indicador de estado visual (Chip moderno con punto indicador)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Abre un modal completo con la información detallada del incidente.
  static void showDetail(
    BuildContext context,
    Incident incident, {
    ApiClient? api,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (catName, catColor, catBg, catIcon) = getCategoryMeta(
      incident.type,
      isDark,
    );
    final (statusLabel, statusColor, statusBg) = getStatusMeta(
      incident.status,
      isDark,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCanvas : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra de arrastre superior
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Encabezado de categoría y estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: catBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(catIcon, color: catColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          catName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: catColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Título y descripción
              Text(
                incident.type,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkText : AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                incident.description.isNotEmpty
                    ? incident.description
                    : 'Sin descripción detallada.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),

              // Datos clave
              _buildDetailRow(
                icon: Icons.place_rounded,
                title: 'Ubicación',
                value: incident.location.isNotEmpty
                    ? incident.location
                    : 'Cartagena de Indias',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildDetailRow(
                icon: Icons.calendar_today_rounded,
                title: 'Fecha y hora',
                value: incident.createdAt != null
                    ? '${incident.createdAt!.day.toString().padLeft(2, "0")}/${incident.createdAt!.month.toString().padLeft(2, "0")}/${incident.createdAt!.year} ${incident.createdAt!.hour.toString().padLeft(2, "0")}:${incident.createdAt!.minute.toString().padLeft(2, "0")}'
                    : 'Reciente',
                isDark: isDark,
              ),
              if (incident.latitude != null && incident.longitude != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  icon: Icons.my_location_rounded,
                  title: 'Coordenadas GPS',
                  value:
                      '${incident.latitude!.toStringAsFixed(5)}, ${incident.longitude!.toStringAsFixed(5)}',
                  isDark: isDark,
                ),
              ],

              // Galería de fotos si existen
              if (incident.imageUrls.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Evidencias adjuntas (${incident.imageUrls.length})',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 75,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: incident.imageUrls.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (_, index) {
                      final url = incident.imageUrls[index];
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 80,
                          color: isDark ? AppColors.darkCard : Colors.black12,
                          child: EvidenceImage(
                            url: url,
                            api: api,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Botón cerrar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkCardHover
                        : const Color(0xFFE2E8F0),
                    foregroundColor: isDark
                        ? AppColors.darkText
                        : AppColors.navy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? AppColors.brightBlue : AppColors.blue,
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkTextMuted : AppColors.muted,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.navy,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
