import 'package:flutter/foundation.dart';

import 'voice_engine_stub.dart'
    if (dart.library.js_interop) 'voice_engine_web.dart'
    if (dart.library.html) 'voice_engine_web.dart';

/// Servicio central de navegación por voz para Cartagena Segura.
/// Gestiona instrucciones en español, encolamiento inteligente, control de desvíos,
/// alertas de zonas de riesgo y prevención de repeticiones en bucle.
class VoiceNavigationService {
  VoiceNavigationService._() {
    _engine = createPlatformVoiceEngine();
  }

  static final VoiceNavigationService instance = VoiceNavigationService._();

  late final PlatformVoiceEngine _engine;

  final ValueNotifier<bool> isMuted = ValueNotifier<bool>(false);

  // Registro de maniobras y tramos ya anunciados para evitar repeticiones
  final Map<String, Set<int>> _spokenManeuverBrackets = {};
  String? _lastSpokenText;
  DateTime? _lastSpokenTime;

  /// Cambia el estado de silencio
  void toggleMute() {
    isMuted.value = !isMuted.value;
    if (isMuted.value) {
      stop();
    } else {
      speak('Instrucciones por voz activadas.', force: true);
    }
  }

  /// Detiene inmediatamente cualquier locución en curso
  void stop() {
    _engine.stop();
  }

  /// Reinicia la memoria de la sesión para una nueva ruta
  void resetSession() {
    _spokenManeuverBrackets.clear();
    _lastSpokenText = null;
    _lastSpokenTime = null;
    stop();
  }

  /// Reproduce un texto si la voz no está silenciada y no es un duplicado reciente
  void speak(String text, {bool force = false}) {
    if (isMuted.value) return;

    final now = DateTime.now();
    if (!force && _lastSpokenText == text) {
      final elapsed = _lastSpokenTime != null
          ? now.difference(_lastSpokenTime!).inSeconds
          : 999;
      if (elapsed < 8) return; // Evita ecos y disparos en ráfaga
    }

    _lastSpokenText = text;
    _lastSpokenTime = now;
    _engine.speak(text);
  }

  /// Anuncio de inicio de navegación
  void announceStart(String destinationName) {
    resetSession();
    speak(
      'Iniciando navegación hacia $destinationName. Conduce con precaución y sigue la ruta recomendada.',
      force: true,
    );
  }

  /// Anuncia una maniobra por voz respetando los umbrales de distancia
  void announceManeuver({
    required String maneuverKey,
    required String actionText,
    required double distanceMeters,
  }) {
    if (isMuted.value) return;

    final brackets = _spokenManeuverBrackets.putIfAbsent(
      maneuverKey,
      () => <int>{},
    );

    // Bracket 500m (450m - 550m)
    if (distanceMeters >= 450 &&
        distanceMeters <= 550 &&
        !brackets.contains(500)) {
      brackets.add(500);
      speak('En 500 metros, $actionText.');
      return;
    }

    // Bracket 200m (180m - 250m)
    if (distanceMeters >= 180 &&
        distanceMeters <= 250 &&
        !brackets.contains(200)) {
      brackets.add(200);
      speak('En 200 metros, $actionText.');
      return;
    }

    // Bracket 50m (40m - 80m)
    if (distanceMeters >= 40 &&
        distanceMeters <= 80 &&
        !brackets.contains(50)) {
      brackets.add(50);
      speak('En 50 metros, prepárate para $actionText.');
      return;
    }

    // Bracket inminente (< 25m)
    if (distanceMeters < 25 && !brackets.contains(0)) {
      brackets.add(0);
      final immediateText = actionText.toLowerCase().contains('gira')
          ? actionText
          : 'Gira ahora: $actionText';
      speak(immediateText, force: true);
      return;
    }
  }

  /// Anuncio de desvío de la ruta establecida
  void announceDeviation() {
    speak(
      'Te has desviado de la ruta. Recalculando recorrido para mayor seguridad...',
      force: true,
    );
  }

  /// Anuncio de confirmación de llegada
  void announceArrival() {
    speak('Has llegado a tu destino. Navegación finalizada.', force: true);
  }

  /// Alerta preventiva de incidente/peligro detectado en la trayectoria
  void announceHazard({
    required String hazardType,
    required double distanceMeters,
  }) {
    if (isMuted.value) return;
    final bracket = distanceMeters > 150 ? 250 : 100;
    final hazardKey = 'hazard_${hazardType}_$bracket';

    final brackets = _spokenManeuverBrackets.putIfAbsent(
      hazardKey,
      () => <int>{},
    );
    if (!brackets.contains(bracket)) {
      brackets.add(bracket);
      final distFormatted = distanceMeters.round();
      speak(
        'Alerta preventiva: a $distFormatted metros se reporta $hazardType en la vía.',
      );
    }
  }
}
