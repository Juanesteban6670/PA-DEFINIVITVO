import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cartagena_segura/core/data/api_client.dart';
import 'package:cartagena_segura/shared/theme.dart';

/// Servicio para verificar nuevas versiones de Cartagena Segura
/// e informar amigablemente al usuario para actualizar desde la descarga oficial.
class VersionCheckService {
  VersionCheckService._();
  static final VersionCheckService instance = VersionCheckService._();

  DateTime? _lastPromptTime;

  /// Comprueba con el backend si hay una versión superior disponible.
  /// [showNoUpdateNotice] permite avisar al usuario si ya tiene la última versión (útil si presiona un botón).
  Future<void> checkForUpdates(
    BuildContext context,
    ApiClient api, {
    bool showNoUpdateNotice = false,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      return;
    }
    // Evitar preguntar más de una vez cada 2 horas de forma automática
    if (!showNoUpdateNotice && _lastPromptTime != null) {
      final elapsed = DateTime.now().difference(_lastPromptTime!);
      if (elapsed < const Duration(hours: 2)) return;
    }

    try {
      final currentAppVersion = (await PackageInfo.fromPlatform()).version;
      final dynamic response = await api
          .get('System/Version')
          .timeout(const Duration(seconds: 4), onTimeout: () => null)
          .catchError((_) => null);

      if (response is Map<String, dynamic>) {
        final latestVersion =
            response['latestVersion']?.toString() ?? currentAppVersion;
        final releaseNotes =
            response['releaseNotes']?.toString() ??
            'Nueva versión con mejoras de seguridad, rendimiento y sincronización en tiempo real.';
        final storeUrl = Uri.tryParse(
          response['storeUrlAndroid']?.toString() ?? '',
        );
        if (storeUrl == null ||
            storeUrl.scheme != 'https' ||
            storeUrl.host != 'github.com') {
          return;
        }

        final isNewer = _compareVersions(latestVersion, currentAppVersion) > 0;
        final forceUpdate = response['forceUpdate'] == true;

        if (isNewer && context.mounted) {
          _lastPromptTime = DateTime.now();
          await _showUpdateDialog(
            context,
            latestVersion: latestVersion,
            currentAppVersion: currentAppVersion,
            releaseNotes: releaseNotes,
            storeUrl: storeUrl,
            forceUpdate: forceUpdate,
          );
        } else if (showNoUpdateNotice && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Cartagena Segura está actualizada a la última versión (v$currentAppVersion)',
              ),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (_) {
      // Falla silenciosa si no hay conectividad para el chequeo de versión
    }
  }

  int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      final parts2 = v2.split('.').map((p) => int.tryParse(p) ?? 0).toList();
      for (var i = 0; i < parts1.length && i < parts2.length; i++) {
        if (parts1[i] > parts2[i]) return 1;
        if (parts1[i] < parts2[i]) return -1;
      }
      return parts1.length.compareTo(parts2.length);
    } catch (_) {
      return 0;
    }
  }

  Future<void> _showUpdateDialog(
    BuildContext context, {
    required String latestVersion,
    required String releaseNotes,
    required Uri storeUrl,
    required String currentAppVersion,
    required bool forceUpdate,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog<void>(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogContext) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            backgroundColor: isDark ? AppColors.darkCard : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.brightBlue : AppColors.blue)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.system_update_rounded,
                    color: isDark ? AppColors.brightBlue : AppColors.blue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Nueva versión disponible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.darkText : AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.brightBlue : AppColors.blue)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Versión $latestVersion (actual: $currentAppVersion)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.brightBlue : AppColors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Hay una actualización lista con mejoras de estabilidad, notificaciones en tiempo real y optimizaciones para Cartagena Segura.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Novedades:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkText : AppColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  releaseNotes,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                  ),
                ),
              ],
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Más tarde',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextMuted : AppColors.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ElevatedButton(
                onPressed: () async {
                  final opened = await launchUrl(
                    storeUrl,
                    mode: LaunchMode.externalApplication,
                  );
                  if (dialogContext.mounted && opened && !forceUpdate) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColors.brightBlue
                      : AppColors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Actualizar ahora',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
