import 'package:admin_web/app/admin_shell.dart';
import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/dashboard/application/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

ResumenVentas _resumen(double ingresos) => ResumenVentas(
  ingresosTotales: ingresos,
  moneda: 'COP',
  totalReservasCompletadas: 1,
  serviciosMasPedidos: const [],
);

void main() {
  testWidgets('un nuevo login no muestra los datos de la sesión anterior', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final scheduling = MockSchedulingRepository();
    var ingresos = 111000.0;
    when(
      () => scheduling.resumenVentas(desde: any(named: 'desde'), hasta: any(named: 'hasta')),
    ).thenAnswer((_) async => _resumen(ingresos));
    final container = ProviderContainer(
      overrides: [schedulingRepositoryProvider.overrideWithValue(scheduling)],
    );
    addTearDown(container.dispose);

    Future<void> montarShell(String userId) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AdminShell(
              key: ValueKey(userId),
              user: UserProfile(id: userId, email: '$userId@x.co', roles: const [UserRole.adminTenant]),
            ),
          ),
        ),
      );
    }

    // Sesión del tenant A.
    await montarShell('a');
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(dashboardControllerProvider).resumen?.ingresosTotales, 111000);

    // Logout (el router saca el shell) y entra el admin del tenant B.
    await tester.pumpWidget(const SizedBox.shrink());
    ingresos = 222000;
    await montarShell('b');

    // Desde el primer frame no queda rastro del resumen de A.
    expect(container.read(dashboardControllerProvider).resumen?.ingresosTotales, isNot(111000));
    await tester.pump(const Duration(seconds: 1));
    expect(container.read(dashboardControllerProvider).resumen?.ingresosTotales, 222000);
  });
}
