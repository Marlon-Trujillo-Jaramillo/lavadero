import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/client/vehicles/vehicles_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockVehiculoRepository extends Mock implements VehiculoRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

final _mazda = Vehiculo(
  id: 'v-1',
  placa: 'ABC123',
  tipo: TipoVehiculo.camioneta,
  marca: 'Mazda',
  creadoEn: DateTime(2026, 11, 15),
);

void main() {
  late MockVehiculoRepository repo;
  late MockAuthRepository auth;

  setUpAll(() => registerFallbackValue(TipoVehiculo.automovil));

  setUp(() {
    repo = MockVehiculoRepository();
    auth = MockAuthRepository();
    when(() => auth.restoreSession()).thenAnswer((_) async => null);
  });

  Future<void> pintar(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehiculoRepositoryProvider.overrideWithValue(repo),
          authRepositoryProvider.overrideWithValue(auth),
        ],
        child: MaterialApp(
          theme: LavaderoTheme.light(),
          home: const VehiclesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sin vehículos muestra el estado vacío con la acción de agregar',
      (tester) async {
    when(() => repo.misVehiculos()).thenAnswer((_) async => []);
    await pintar(tester);

    expect(find.text('Tu garaje está vacío'), findsOneWidget);
    expect(find.text('Agregar vehículo'), findsOneWidget);
  });

  testWidgets('lista los vehículos con su placa y descripción', (tester) async {
    when(() => repo.misVehiculos()).thenAnswer((_) async => [_mazda]);
    await pintar(tester);

    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('Camioneta · Mazda'), findsOneWidget);
    expect(find.text('1 vehículo guardado'), findsOneWidget);
  });

  testWidgets('el formulario valida la placa antes de llamar al backend',
      (tester) async {
    when(() => repo.misVehiculos()).thenAnswer((_) async => []);
    await pintar(tester);

    await tester.tap(find.text('Agregar vehículo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'AB1');
    await tester.tap(find.text('Guardar vehículo'));
    await tester.pumpAndSettle();

    expect(find.text('De 5 a 8 letras o números (ej. ABC123)'), findsOneWidget);
    verifyNever(() => repo.registrar(
          placa: any(named: 'placa'),
          tipo: any(named: 'tipo'),
          marca: any(named: 'marca'),
          color: any(named: 'color'),
        ));
  });

  testWidgets('guardar agrega el vehículo a la lista', (tester) async {
    when(() => repo.misVehiculos()).thenAnswer((_) async => []);
    when(() => repo.registrar(
          placa: any(named: 'placa'),
          tipo: any(named: 'tipo'),
          marca: any(named: 'marca'),
          color: any(named: 'color'),
        )).thenAnswer((_) async => _mazda);
    await pintar(tester);

    await tester.tap(find.text('Agregar vehículo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'abc-123');
    await tester.tap(find.text('Camioneta'));
    await tester.tap(find.text('Guardar vehículo'));
    await tester.pumpAndSettle();

    expect(find.text('ABC123'), findsOneWidget);
    verify(() => repo.registrar(
          placa: 'abc-123',
          tipo: TipoVehiculo.camioneta,
          marca: '',
          color: '',
        )).called(1);
  });

  testWidgets('quitar pide confirmación y archiva', (tester) async {
    when(() => repo.misVehiculos()).thenAnswer((_) async => [_mazda]);
    when(() => repo.archivar('v-1')).thenAnswer((_) async {});
    await pintar(tester);

    await tester.tap(find.byTooltip('Quitar vehículo'));
    await tester.pumpAndSettle();
    expect(find.text('Quitar ABC123'), findsOneWidget);
    await tester.tap(find.text('Quitar'));
    await tester.pumpAndSettle();

    verify(() => repo.archivar('v-1')).called(1);
    expect(find.text('Tu garaje está vacío'), findsOneWidget);
  });
}
