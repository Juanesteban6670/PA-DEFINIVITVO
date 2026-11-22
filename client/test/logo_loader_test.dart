import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cartagena_segura/shared/logo_loader.dart';

void main() {
  testWidgets('LogoLoaderScreen renders with accessible labels and controls',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LogoLoaderScreen(),
      ),
    );

    // Initial frame renders
    expect(find.byType(LogoLoaderScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Cargando Cartagena Segura'), findsOneWidget);
    expect(find.text('Pausar'), findsOneWidget);
    expect(find.text('Reiniciar'), findsOneWidget);

    // Tap pause button
    await tester.tap(find.text('Pausar'));
    await tester.pump();
    expect(find.text('Reanudar'), findsOneWidget);

    // Tap reanudar button
    await tester.tap(find.text('Reanudar'));
    await tester.pump();
    expect(find.text('Pausar'), findsOneWidget);

    // Tap replay button
    await tester.tap(find.text('Reiniciar'));
    await tester.pump();
    expect(find.text('Pausar'), findsOneWidget);
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
    // When animations are disabled, controls are disabled
    final pauseButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Pausar'),
    );
    expect(pauseButton.onPressed, isNull);

    final replayButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Reiniciar'),
    );
    expect(replayButton.onPressed, isNull);
  });
}
