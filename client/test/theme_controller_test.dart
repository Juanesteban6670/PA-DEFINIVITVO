import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartagena_segura/shared/theme.dart';

void main() {
  group('ThemeModeController', () {
    test('initializes and allows setting mode', () async {
      final controller = ThemeModeController();
      expect(controller.mode, ThemeMode.system);

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.mode, ThemeMode.dark);

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.mode, ThemeMode.light);

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.mode, ThemeMode.system);
    });

    test('buildAppTheme returns a valid light theme', () {
      final theme = buildAppTheme();
      expect(theme.brightness, Brightness.light);
      expect(theme.scaffoldBackgroundColor, AppColors.canvas);
      expect(theme.colorScheme.primary, AppColors.blue);
    });

    test('buildDarkAppTheme returns a valid dark theme', () {
      final theme = buildDarkAppTheme();
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, AppColors.darkCanvas);
      expect(theme.colorScheme.primary, AppColors.brightBlue);
    });
  });
}
