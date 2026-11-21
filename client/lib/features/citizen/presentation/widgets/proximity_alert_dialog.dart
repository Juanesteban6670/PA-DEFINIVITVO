import 'package:flutter/material.dart';
import 'package:cartagena_segura/core/services/proximity_alert_service.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Modal interactivo y moderno para visualizar los detalles de una alerta de proximidad a zona de riesgo.
class ProximityAlertDialog extends StatelessWidget {
  const ProximityAlertDialog({
    required this.alert,
    required this.onViewOnMap,
    super.key,
  });

  final ProximityZoneAlert alert;
  final VoidCallback onViewOnMap;

  static void show(
    BuildContext context, {
    required ProximityZoneAlert alert,
    required VoidCallback onViewOnMap,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => ProximityAlertDialog(alert: alert, onViewOnMap: onViewOnMap),
    );
  }

  (Color, Color, IconData) _getRiskMeta(bool isDark) {
    if (alert.riskLevel == 'ALTO') {
      return (
        isDark ? AppColors.darkRed : AppColors.red,
        (isDark ? AppColors.darkRed : AppColors.red).withValues(alpha: 0.15),
        Icons.warning_rounded,
      );
    }
    if (alert.riskLevel == 'MEDIO') {
      return (
        isDark ? AppColors.darkAmber : AppColors.amber,
        (isDark ? AppColors.darkAmber : AppColors.amber).withValues(alpha: 0.15),
        Icons.shield_outlined,
      );
    }
    return (
      isDark ? AppColors.darkGreen : AppColors.green,
      (isDark ? AppColors.darkGreen : AppColors.green).withValues(alpha: 0.15),
      Icons.check_circle_outline_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (riskColor, riskBg, riskIcon) = _getRiskMeta(isDark);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: riskBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(riskIcon, color: riskColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerta de Proximidad',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Zona de Riesgo Detectada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: riskColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCanvas : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.border,
                width: 0.8,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.fmd_good_rounded, size: 16, color: isDark ? AppColors.brightBlue : AppColors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        alert.zoneName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkText : AppColors.navy,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _buildInfoBadge(
                      label: 'Nivel: ${alert.riskLevel}',
                      color: riskColor,
                      bg: riskBg,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoBadge(
                      label: 'A ~${alert.formattedDistance}',
                      color: isDark ? AppColors.darkText : AppColors.navy,
                      bg: isDark ? AppColors.darkCardHover : const Color(0xFFE2E8F0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Incidentes registrados
          Text(
            'Incidentes registrados en el sector (${alert.incidentCount}):',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: alert.recentTypes.map((type) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkText : AppColors.blue,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          // Recomendación de seguridad
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? AppColors.darkAmber : AppColors.amber).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: isDark ? AppColors.darkAmber : AppColors.amber,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Se recomienda transitar por vías concurridas y bien iluminadas. En caso de emergencia, comunícate al 123.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: isDark ? AppColors.darkTextMuted : const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            ProximityAlertService.instance.showPreferencesDialog(context);
          },
          child: Text(
            'Preferencias',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkTextMuted : AppColors.muted,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onViewOnMap();
          },
          icon: const Icon(Icons.map_rounded, size: 16),
          label: const Text('Ver en el mapa', style: TextStyle(fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? AppColors.brightBlue : AppColors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBadge({
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
