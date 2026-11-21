import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/inventory/application/inventory_controller.dart';
import 'package:admin_web/features/inventory/inventory_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockInventarioRepository extends Mock implements InventarioRepository {}

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

void main() {
  late MockInventarioRepository repo;
  late MockSchedulingRepository scheduling;

  const shampoo = InsumoStock(
    id: 'i1',
    nombre: 'Shampoo neutro',
    unidad: UnidadMedida.ml,
    costoUnitario: 12,
    moneda: 'COP',
    sucursalId: 'b1',
    cantidad: 400,
    minimo: 500,
    bajoMinimo: true,
  );
  const cera = InsumoStock(
    id: 'i2',
    nombre: 'Cera',
    unidad: UnidadMedida.g,
    costoUnitario: 80,
    moneda: 'COP',
    sucursalId: 'b1',
    cantidad: 2000,
    minimo: 0,
    bajoMinimo: false,
  );
  const lavado = CostoServicio(
    servicioId: 's1',
    nombre: 'Lavado full',
    activo: true,
    precio: 45000,
    moneda: 'COP',
    lineas: [
      LineaCosto(
        insumoId: 'i1',
        insumo: 'Shampoo neutro',
        unidad: UnidadMedida.ml,
        cantidad: 40,
        costo: 480,
      ),
    ],
    costoInsumos: 480,
    margen: 44520,
    margenPorcentaje: 99,
  );

  setUpAll(() => registerFallbackValue(UnidadMedida.ml));

  setUp(() {
    repo = MockInventarioRepository();
    scheduling = MockSchedulingRepository();
    when(() => scheduling.listarSucursales()).thenAnswer(
      (_) async => const [
        Sucursal(id: 'b1', nombre: 'Sede Centro', capacidadSimultanea: 2),
      ],
    );
    when(
      () => repo.insumos(sucursalId: 'b1'),
    ).thenAnswer((_) async => const [shampoo, cera]);
    when(() => repo.costos()).thenAnswer((_) async => const [lavado]);
  });

  Future<void> pintar(WidgetTester tester, {bool dueno = true}) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventarioRepositoryProvider.overrideWithValue(repo),
          schedulingRepositoryProvider.overrideWithValue(scheduling),
          puedeGestionarInventarioProvider.overrideWithValue(dueno),
        ],
        child: MaterialApp(
          theme: LavaderoTheme.light(),
          home: const Scaffold(body: InventoryScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el stock con lo que hay que reponer', (tester) async {
    await pintar(tester);

    expect(find.text('Reponer'), findsOneWidget);
    expect(find.text('400 ml'), findsOneWidget);
    expect(find.text('2.000 g'), findsOneWidget);
    expect(find.text(r'$12.000 por litro'), findsOneWidget);
    // Valor en bodega: 400 × 12 + 2000 × 80.
    expect(find.text(r'$164.800'), findsOneWidget);
  });

  testWidgets('registrar una entrada acepta miles con punto', (tester) async {
    when(
      () => repo.registrarEntrada(
        insumoId: 'i1',
        sucursalId: 'b1',
        cantidad: 1500,
        nota: 'Factura 88',
      ),
    ).thenAnswer(
      (_) async => MovimientoInventario(
        id: 'm1',
        tipo: TipoMovimiento.entrada,
        cantidad: 1500,
        saldo: 1900,
        creadoEn: DateTime(2026, 11, 20),
      ),
    );
    await pintar(tester);

    await tester.tap(find.byTooltip('Registrar entrada').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Cantidad que llega'),
      '1.500',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nota (opcional)'),
      'Factura 88',
    );
    await tester.tap(find.text('Registrar'));
    await tester.pumpAndSettle();

    verify(
      () => repo.registrarEntrada(
        insumoId: 'i1',
        sucursalId: 'b1',
        cantidad: 1500,
        nota: 'Factura 88',
      ),
    ).called(1);
  });

  testWidgets('crear un insumo calcula el costo por unidad desde la compra', (
    tester,
  ) async {
    when(
      () => repo.crearInsumo(
        nombre: any(named: 'nombre'),
        unidad: any(named: 'unidad'),
        costoUnitario: any(named: 'costoUnitario'),
      ),
    ).thenAnswer((_) async => 'nuevo');
    await pintar(tester);

    await tester.tap(find.text('Nuevo insumo'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Desengrasante',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Precio de compra'),
      '40.000',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Trae'), '4.000');
    await tester.pump();
    expect(find.text(r'Cuesta $10.000 por litro.'), findsOneWidget);
    await tester.tap(find.text('Crear insumo'));
    await tester.pumpAndSettle();

    verify(
      () => repo.crearInsumo(
        nombre: 'Desengrasante',
        unidad: UnidadMedida.ml,
        costoUnitario: 10,
      ),
    ).called(1);
  });

  testWidgets('el costo por lavado muestra el margen y edita la receta', (
    tester,
  ) async {
    when(
      () => repo.definirReceta(
        servicioId: any(named: 'servicioId'),
        lineas: any(named: 'lineas'),
      ),
    ).thenAnswer((_) async {});
    await pintar(tester);

    await tester.tap(find.text('Costo por lavado'));
    await tester.pumpAndSettle();
    expect(find.text('Margen 99 %'), findsOneWidget);

    await tester.tap(find.text('Editar receta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Cera'), '25');
    await tester.tap(find.text('Guardar receta'));
    await tester.pumpAndSettle();

    verify(
      () => repo.definirReceta(servicioId: 's1', lineas: {'i1': 40, 'i2': 25}),
    ).called(1);
  });

  testWidgets(
    'el admin de sucursal registra movimientos pero no crea insumos',
    (tester) async {
      await pintar(tester, dueno: false);

      expect(find.text('Nuevo insumo'), findsNothing);
      expect(find.byTooltip('Registrar entrada'), findsNWidgets(2));
      await tester.tap(find.text('Costo por lavado'));
      await tester.pumpAndSettle();
      expect(find.text('Editar receta'), findsNothing);
    },
  );

  testWidgets('el kardex muestra cada movimiento con su saldo', (tester) async {
    when(() => repo.movimientos(insumoId: 'i1', sucursalId: 'b1')).thenAnswer(
      (_) async => [
        MovimientoInventario(
          id: 'm2',
          tipo: TipoMovimiento.consumo,
          cantidad: -40,
          saldo: 400,
          reservaId: 'r1',
          creadoEn: DateTime(2026, 11, 20, 10),
        ),
        MovimientoInventario(
          id: 'm1',
          tipo: TipoMovimiento.entrada,
          cantidad: 440,
          saldo: 440,
          nota: 'Factura 88',
          creadoEn: DateTime(2026, 11, 19, 9),
        ),
      ],
    );
    await pintar(tester);

    await tester.tap(find.byTooltip('Ver movimientos').first);
    await tester.pumpAndSettle();

    expect(find.text('Lavado completado'), findsOneWidget);
    expect(find.text('-40 ml'), findsOneWidget);
    expect(find.text('Factura 88'), findsOneWidget);
    expect(find.text('Queda 400 ml'), findsOneWidget);
  });
}
