import 'package:flutter/material.dart';

import 'package:cartagena_segura/core/data/realtime_service.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Indicador visual interactivo del estado de sincronización en tiempo real.
class LiveStatusBadge extends StatelessWidget {
  const LiveStatusBadge({
    required this.realtimeService,
    this.compact = false,
    super.key,
  });

  final RealtimeAlertService? realtimeService;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (realtimeService == null) return const SizedBox.shrink();

    return ValueListenableBuilder<RealtimeMode>(
      valueListenable: realtimeService!.connectionMode,
      builder: (context, mode, _) {
        final (Color dotColor, String label, String tooltip) = switch (mode) {
          RealtimeMode.webSocket => (
              AppColors.green,
              compact ? 'VIVO' : 'EN VIVO',
              'Conexión WebSocket STOMP activa (latencia cero)',
            ),
          RealtimeMode.pollingFallback => (
              AppColors.brightBlue,
              compact ? 'SYNC' : 'EN LÍNEA',
              'Sincronización adaptativa activa (modo resiliente)',
            ),
          RealtimeMode.connecting => (
              AppColors.amber,
              compact ? '...' : 'CONECTANDO',
              'Estableciendo canal en tiempo real...',
            ),
          RealtimeMode.disconnected => (
              AppColors.muted,
              compact ? 'OFF' : 'DESCONECTADO',
              'Sin conexión al canal en tiempo real',
            ),
        };

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Tooltip(
          message: tooltip,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 8,
              vertical: compact ? 3 : 4,
            ),
            decoration: BoxDecoration(
              color: dotColor.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: dotColor.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: dotColor.withValues(alpha: 0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: compact ? 10 : 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: dotColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
