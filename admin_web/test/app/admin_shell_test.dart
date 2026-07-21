import 'package:admin_web/app/admin_shell.dart';
import 'package:admin_web/app/di/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

UserProfile _userWith(List<UserRole> roles) => UserProfile(
      id: 'u1',
      email: 'admin@example.com',
      roles: roles,
    );

/// `AdminShell` muestra `DashboardScreen` por defecto (índice 0), que llama a
/// `schedulingRepositoryProvider` al construirse — se sobreescribe con un mock
/// para que estos tests de navegación no dependan de red.
ProviderScope _appConDashboardMockeado(Widget home) {
  final schedulingRepository = MockSchedulingRepository();
  when(() => schedulingRepository.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      )).thenAnswer(
    (_) async => const ResumenVentas(
      ingresosTotales: 0,
      moneda: 'COP',
      totalReservasCompletadas: 0,
      serviciosMasPedidos: [],
    ),
  );
  return ProviderScope(
    overrides: [schedulingRepositoryProvider.overrideWithValue(schedulingRepository)],
    child: MaterialApp(home: home),
  );
}

void main() {
  Future<void> useDesktopSurface(WidgetTester tester) async {
    // AdminShell usa NavigationRail con 8-9 destinos: en el tamaño de
    // superficie por defecto de flutter_test (800x600) desborda. admin_web
    // es una app de escritorio/web, así que se prueba con una superficie
    // representativa de ese contexto.
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('hides the "Tenants" section for a non-super-admin',
      (tester) async {
    await useDesktopSurface(tester);
    await tester.pumpWidget(
      _appConDashboardMockeado(AdminShell(user: _userWith([UserRole.adminTenant]))),
    );

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Tenants'), findsNothing);
  });

  testWidgets('shows the "Tenants" section for a super-admin', (tester) async {
    await useDesktopSurface(tester);
    await tester.pumpWidget(
      _appConDashboardMockeado(AdminShell(user: _userWith([UserRole.superAdmin]))),
    );

    expect(find.text('Tenants'), findsWidgets);
  });
}
