import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

void main() {
  Widget app(Widget child) => MaterialApp(
    theme: LavaderoTheme.light(),
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('se activa con teclado (Tab + Enter/Espacio) y muestra anillo de foco', (
    tester,
  ) async {
    var toques = 0;
    await tester.pumpWidget(
      app(Pressable(onTap: () => toques++, child: const Text('Tarjeta'))),
    );

    expect(find.byType(FocusRing), findsOneWidget);
    expect(tester.widget<FocusRing>(find.byType(FocusRing)).visible, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(tester.widget<FocusRing>(find.byType(FocusRing)).visible, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(toques, 2);
  });

  testWidgets('se anuncia como botón y sin onTap queda deshabilitado', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(app(const Pressable(child: Text('Inactiva'))));

    final semantics = tester.getSemantics(find.text('Inactiva'));
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, isNot(true));
    handle.dispose();
  });
}
