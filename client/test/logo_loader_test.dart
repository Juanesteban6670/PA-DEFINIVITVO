import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartagena_segura/shared/logo_loader.dart';

void main() {
  testWidgets('LogoLoaderScreen renders with accessible labels and statement',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LogoLoaderScreen(),
      ),
    );

    // Initial frame renders
    expect(find.byType(LogoLoaderScreen), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'Cargando Cartagena Segura')), findsOneWidget);
    expect(find.text('Sistema Distrital de Seguridad Ciudadana'), findsOneWidget);

    // Control buttons were removed per user request
    expect(find.text('Pausar'), findsNothing);
    expect(find.text('Reiniciar'), findsNothing);
  });

  testWidgets('LogoLoaderScreen respects reduced motion', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: LogoLoaderScreen(),
        ),
      ),
    );

    expect(find.byType(LogoLoaderScreen), findsOneWidget);
    expect(find.text('Sistema Distrital de Seguridad Ciudadana'), findsOneWidget);
  });
}
