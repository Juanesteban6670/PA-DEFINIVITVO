import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Motor de síntesis de voz en tiempo real para Flutter Web utilizando la API nativa
/// window.speechSynthesis (compatible con Chrome, Safari, Edge, Firefox y navegadores móviles).
class PlatformVoiceEngine {
  void speak(String text, {double rate = 1.05, double pitch = 1.0, String lang = 'es-CO'}) {
    try {
      final synth = web.window.speechSynthesis;
      // Cancela locuciones anteriores para que la instrucción inmediata no tenga retardo
      synth.cancel();

      final utterance = web.SpeechSynthesisUtterance(text);
      utterance.lang = lang;
      utterance.rate = rate;
      utterance.pitch = pitch;

      synth.speak(utterance);
    } catch (e) {
      debugPrint('Error en Web Speech Synthesis: $e');
    }
  }

  void stop() {
    try {
      web.window.speechSynthesis.cancel();
    } catch (_) {}
  }

  bool get isSupported => true;
}

PlatformVoiceEngine createPlatformVoiceEngine() => PlatformVoiceEngine();
