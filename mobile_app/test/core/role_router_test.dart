import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/core/role_router.dart';
import 'package:mocktail/mocktail.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

UserProfile _userWith(List<UserRole> roles) => UserProfile(
      id: 'u1',
      email: 'user@example.com',
      roles: roles,
    );

/// `ClienteShell` renderiza `CatalogScreen` (usa `catalogRepositoryProvider`) y
/// `EmpleadoShell` renderiza `ShiftsScreen` (usa `schedulingRepositoryProvider` +
/// `authControllerProvider`, que a su vez llama a `authRepositoryProvider.restoreSession()`
/// al construirse) — todos se sobreescriben con mocks para que estos tests de
/// navegación no dependan de red/almacenamiento seguro real.
Widget _appConNavegacion(Widget home) {
  final catalogRepository = MockCatalogRepository();
  when(() => catalogRepository.listarActivos()).thenAnswer((_) async => []);

  final schedulingRepository = MockSchedulingRepository();
  when(() => schedulingRepository.agendaDelDia(
        sucursalId: any(named: 'sucursalId'),
        fecha: any(named: 'fecha'),
      )).thenAnswer((_) async => []);

  final authRepository = MockAuthRepository();
  when(() => authRepository.restoreSession()).thenAnswer((_) async => null);

  return ProviderScope(
    overrides: [
      catalogRepositoryProvider.overrideWithValue(catalogRepository),
      schedulingRepositoryProvider.overrideWithValue(schedulingRepository),
      authRepositoryProvider.overrideWithValue(authRepository),
    ],
    child: MaterialApp(home: home),
  );
}

void main() {
  testWidgets('shows ClienteShell (bottom nav Catálogo) for CLIENTE-only',
      (tester) async {
    await tester.pumpWidget(
      _appConNavegacion(RoleRouter(user: _userWith([UserRole.cliente]))),
    );
    expect(find.text('Catálogo'), findsWidgets);
    expect(find.text('Turnos'), findsNothing);
  });

  testWidgets('shows EmpleadoShell (bottom nav Turnos) for EMPLEADO-only',
      (tester) async {
    await tester.pumpWidget(
      _appConNavegacion(RoleRouter(user: _userWith([UserRole.empleado]))),
    );
    expect(find.text('Turnos'), findsWidgets);
    expect(find.text('Catálogo'), findsNothing);
  });

  testWidgets(
      'shows a role selector when the user has both CLIENTE and EMPLEADO, '
      'then routes to the picked shell', (tester) async {
    await tester.pumpWidget(
      _appConNavegacion(
        RoleRouter(user: _userWith([UserRole.cliente, UserRole.empleado])),
      ),
    );

    expect(find.text('¿Cómo quieres continuar?'), findsOneWidget);
    expect(find.text('Catálogo'), findsNothing);
    expect(find.text('Turnos'), findsNothing);

    await tester.tap(find.text('Como empleado'));
    await tester.pumpAndSettle();

    expect(find.text('Turnos'), findsWidgets);
  });
}
