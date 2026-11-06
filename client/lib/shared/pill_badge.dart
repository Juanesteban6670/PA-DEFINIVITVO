import 'package:flutter/material.dart';

import 'theme.dart';

/// Insignia estilo píldora/cápsula con indicador de estado (status dot)
/// optimizada para modo claro y modo oscuro.
class PillBadge extends StatelessWidget {
  const PillBadge({
    required this.value,
    this.isPriority = false,
    this.compact = false,
    super.key,
  });

  final String value;
  final bool isPriority;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (label, color) = switch ((isPriority, value.toUpperCase())) {
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

    final bgAlpha = isDark ? 0.22 : 0.12;
    final borderAlpha = isDark ? 0.35 : 0.22;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: borderAlpha),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isDark ? 0.6 : 0.3),
                  blurRadius: 4,
                  spreadRadius: 0.5,
                ),
              ],
            ),
          ),
          SizedBox(width: compact ? 4 : 5),
          Text(
            label,
            style: TextStyle(
              color: isDark ? color : color.withValues(alpha: 0.95),
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
