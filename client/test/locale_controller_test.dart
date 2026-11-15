import 'package:flutter_test/flutter_test.dart';

import 'package:cartagena_segura/core/localization/app_strings.dart';
import 'package:cartagena_segura/core/localization/locale_controller.dart';

void main() {
  group('LocaleController & AppStrings', () {
    test('initializes with Spanish by default', () {
      final controller = LocaleController();
      expect(controller.language, AppLanguage.es);
      expect(controller.locale.languageCode, 'es');
      expect(controller.isEnglish, isFalse);
    });

    test('allows setting language to English and toggling', () async {
      final controller = LocaleController();

      await controller.setLanguage(AppLanguage.en);
      expect(controller.language, AppLanguage.en);
      expect(controller.locale.languageCode, 'en');
      expect(controller.isEnglish, isTrue);

      await controller.toggleLanguage();
      expect(controller.language, AppLanguage.es);
      expect(controller.locale.languageCode, 'es');
      expect(controller.isEnglish, isFalse);
    });

    test('AppStrings contains valid translations for both languages', () {
      final es = AppStrings.es;
      final en = AppStrings.en;

      expect(es.navHome, 'Inicio');
      expect(en.navHome, 'Home');

      expect(es.navReports, 'Reportes');
      expect(en.navReports, 'Reports');

      expect(es.navEmergency, 'Emergencias');
      expect(en.navEmergency, 'Emergency');

      expect(es.sosEmergencyCall, 'Llamada de Emergencia 123');
      expect(en.sosEmergencyCall, 'Emergency Call 123');

      expect(es.safeRouteTitle, 'Asistente de Rutas Seguras');
      expect(en.safeRouteTitle, 'Safe Route Assistant');

      expect(es.reportIncidentTitle, 'Reportar Incidente');
      expect(en.reportIncidentTitle, 'Report Incident');
    });

    test('getCategoryName maps incident categories appropriately in English and Spanish', () {
      expect(AppStrings.es.getCategoryName('HURTO_CELULAR'), 'Hurto / Robo');
      expect(AppStrings.en.getCategoryName('HURTO_CELULAR'), 'Theft / Robbery');

      expect(AppStrings.es.getCategoryName('ACCIDENTE'), 'Accidente de Tránsito');
      expect(AppStrings.en.getCategoryName('ACCIDENTE'), 'Traffic Accident');
    });
  });
}
