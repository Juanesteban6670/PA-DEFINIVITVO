import 'package:flutter/foundation.dart';

/// Implementación stub para plataformas sin soporte Web Speech API nativo.
class PlatformVoiceEngine {
  void speak(String text, {double rate = 1.05, double pitch = 1.0, String lang = 'es-CO'}) {
    debugPrint('[VoiceEngineStub] Hablando: $text');
  }

  void stop() {
    debugPrint('[VoiceEngineStub] Deteniendo locución');
  }

  bool get isSupported => false;
}

PlatformVoiceEngine createPlatformVoiceEngine() => PlatformVoiceEngine();
