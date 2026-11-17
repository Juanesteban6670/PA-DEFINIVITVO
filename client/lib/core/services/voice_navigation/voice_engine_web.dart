import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

/// Motor de síntesis de voz en tiempo real para Flutter Web utilizando la API nativa
/// window.speechSynthesis (compatible con Chrome, Safari, Edge, Firefox y navegadores móviles).
class PlatformVoiceEngine {
  void speak(String text, {double rate = 1.05, double pitch = 1.0, String lang = 'es-CO'}) {
    try {
      final synth = globalContext['speechSynthesis'] as JSObject?;
      if (synth == null) return;

      // Cancela locuciones anteriores para que la instrucción inmediata no tenga retardo
      synth.callMethod('cancel'.toJS);

      final utteranceConstructor =
          globalContext['SpeechSynthesisUtterance'] as JSFunction?;
      if (utteranceConstructor == null) return;

      final utterance =
          utteranceConstructor.callAsConstructor<JSObject>(text.toJS);
      utterance['lang'] = lang.toJS;
      utterance['rate'] = rate.toJS;
      utterance['pitch'] = pitch.toJS;

      synth.callMethod('speak'.toJS, utterance);
    } catch (e) {
      debugPrint('Error en Web Speech Synthesis: $e');
    }
  }

  void stop() {
    try {
      final synth = globalContext['speechSynthesis'] as JSObject?;
      synth?.callMethod('cancel'.toJS);
    } catch (_) {}
  }

  bool get isSupported => true;
}

PlatformVoiceEngine createPlatformVoiceEngine() => PlatformVoiceEngine();
