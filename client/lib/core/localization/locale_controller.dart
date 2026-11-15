import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'app_strings.dart';

/// Controlador reactivo y persistente del idioma de la aplicación.
/// Permite alternar instantáneamente entre Español (es) e Inglés (en) para residentes y turistas.
class LocaleController extends ChangeNotifier {
  LocaleController({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage() {
    _loadLanguage();
  }

  static final LocaleController instance = LocaleController();

  final FlutterSecureStorage _storage;
  static const _storageKey = 'cartagena_app_language';

  AppLanguage _language = AppLanguage.es;

  AppLanguage get language => _language;
  Locale get locale => Locale(_language.code);
  bool get isEnglish => _language == AppLanguage.en;

  AppStrings get strings => AppStrings.ofLanguage(_language);

  Future<void> _loadLanguage() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'en') {
        _language = AppLanguage.en;
        notifyListeners();
      } else if (saved == 'es') {
        _language = AppLanguage.es;
        notifyListeners();
      }
    } catch (_) {
      // Si falla storage, se mantiene Español por defecto
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    try {
      await _storage.write(key: _storageKey, value: language.code);
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final next = _language == AppLanguage.es ? AppLanguage.en : AppLanguage.es;
    await setLanguage(next);
  }
}

/// Proveedor Riverpod para el controlador de idioma
final localeProvider = ChangeNotifierProvider<LocaleController>((ref) {
  return LocaleController.instance;
});

/// Proveedor conveniente para acceder a las cadenas traducidas reactivamente
final l10nProvider = Provider<AppStrings>((ref) {
  final controller = ref.watch(localeProvider);
  return controller.strings;
});
