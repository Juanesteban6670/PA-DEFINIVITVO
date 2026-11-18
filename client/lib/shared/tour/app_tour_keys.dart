import 'package:flutter/material.dart';

/// Claves globales para los elementos destacados en el tutorial ciudadano
abstract final class AppTourKeys {
  /// Pestaña o acceso al Mapa Distrital
  static final navMapKey = GlobalKey(debugLabel: 'tour_nav_map');

  /// Botón o tarjeta de Rutas Seguras
  static final safeRouteKey = GlobalKey(debugLabel: 'tour_safe_route');

  /// Botón de emergencias SOS 123 en la barra superior
  static final sosButtonKey = GlobalKey(debugLabel: 'tour_sos_button');

  /// Pestaña o botón de nuevo reporte ciudadano
  static final navReportsKey = GlobalKey(debugLabel: 'tour_nav_reports');

  /// Acceso al Asistente Ciudadano IA o selector de Liquid Glass
  static final aiAssistantKey = GlobalKey(debugLabel: 'tour_ai_assistant');
}
