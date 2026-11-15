import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'app/router.dart';
import 'core/localization/locale_controller.dart';
import 'shared/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CartagenaApp()));
}

class CartagenaApp extends ConsumerWidget {
  const CartagenaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final themeController = ref.watch(themeModeProvider);
    final themeMode = themeController.mode;
    final localeController = ref.watch(localeProvider);

    if (!session.initialized) {
      return MaterialApp(
        title: 'Cartagena Segura',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        darkTheme: buildDarkAppTheme(),
        themeMode: themeMode,
        locale: localeController.locale,
        supportedLocales: const [Locale('es'), Locale('en')],
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp.router(
      title: 'Cartagena Segura',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildDarkAppTheme(),
      themeMode: themeMode,
      locale: localeController.locale,
      supportedLocales: const [Locale('es'), Locale('en')],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
