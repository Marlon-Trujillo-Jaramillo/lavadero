import 'package:admin_web/features/auth/presentation/admin_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

Future<void> _pintar(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: LavaderoTheme.light(),
        home: const AdminSignupScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _campo(String label) => find.widgetWithText(TextFormField, label);

void main() {
  for (final size in const [
    Size(1440, 1000),
    Size(700, 1100),
    Size(390, 1600),
  ]) {
    testWidgets('se pinta sin desbordes en ${size.width.toInt()} px', (
      tester,
    ) async {
      await _pintar(tester, size);
      expect(tester.takeException(), isNull);
      expect(find.text('Crear mi lavadero'), findsOneWidget);
    });
  }

  testWidgets('propone el código a partir del nombre del lavadero', (
    tester,
  ) async {
    await _pintar(tester, const Size(1440, 1000));
    await tester.enterText(
      _campo('Nombre del lavadero'),
      'Lavadero El Poblado',
    );
    await tester.pump();

    final slug = tester.widget<TextFormField>(_campo('Código del lavadero'));
    expect(slug.controller!.text, 'lavadero-el-poblado');
  });

  testWidgets('si el usuario edita el código, el nombre ya no lo pisa', (
    tester,
  ) async {
    await _pintar(tester, const Size(1440, 1000));
    await tester.enterText(_campo('Código del lavadero'), 'mi-lavadero');
    await tester.enterText(_campo('Nombre del lavadero'), 'Otro Nombre');
    await tester.pump();

    final slug = tester.widget<TextFormField>(_campo('Código del lavadero'));
    expect(slug.controller!.text, 'mi-lavadero');
  });

  testWidgets('valida antes de llamar al backend', (tester) async {
    await _pintar(tester, const Size(1440, 1000));
    await tester.enterText(_campo('Email'), 'no-es-un-correo');
    await tester.enterText(_campo('Contraseña'), '1234');
    await tester.tap(find.text('Crear mi lavadero'));
    await tester.pump();

    expect(find.text('Ingresa el nombre del lavadero'), findsOneWidget);
    expect(find.text('Ingresa un email válido'), findsOneWidget);
    expect(find.text('Mínimo 8 caracteres'), findsWidgets);
  });
}
