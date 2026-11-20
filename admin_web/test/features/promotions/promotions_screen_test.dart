import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/promotions/application/promotions_controller.dart';
import 'package:admin_web/features/promotions/promotions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockPromocionRepository extends Mock implements PromocionRepository {}

void main() {
  late MockPromocionRepository repo;
  final hoy = DateTime.now();
  final inicio = DateTime(hoy.year, hoy.month, hoy.day);

  Promocion promo({
    String id = 'p1',
    String nombre = 'Mañanas de semana',
    TipoPromocion tipo = TipoPromocion.horario,
    bool activa = true,
    int? usosMaximos,
    int usos = 12,
  }) => Promocion(
    id: id,
    nombre: nombre,
    tipo: tipo,
    codigo: tipo == TipoPromocion.cupon ? 'HOLA10' : null,
    tipoDescuento: TipoDescuento.porcentaje,
    valorDescuento: 20,
    dias: tipo == TipoPromocion.horario
        ? const [DiaSemana.martes, DiaSemana.miercoles]
        : const [],
    horaDesde: tipo == TipoPromocion.horario ? '08:00:00' : null,
    horaHasta: tipo == TipoPromocion.horario ? '11:00:00' : null,
    vigenteDesde: inicio.subtract(const Duration(days: 3)),
    vigenteHasta: inicio.add(const Duration(days: 30)),
    usosMaximos: usosMaximos,
    usos: usos,
    activa: activa,
    reservas: 12,
    completadas: 9,
    ingresos: 324000,
    descuentoOtorgado: 81000,
  );

  setUpAll(() {
    registerFallbackValue(TipoPromocion.cupon);
    registerFallbackValue(TipoDescuento.porcentaje);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = MockPromocionRepository();
    when(() => repo.listar()).thenAnswer(
      (_) async => [
        promo(),
        promo(
          id: 'p2',
          nombre: 'Primeros 50',
          tipo: TipoPromocion.cupon,
          usosMaximos: 50,
          usos: 50,
        ),
      ],
    );
  });

  Future<void> pintar(WidgetTester tester, {bool dueno = true}) async {
    tester.view.physicalSize = const Size(1440, 1100);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          promocionRepositoryProvider.overrideWithValue(repo),
          puedeGestionarPromocionesProvider.overrideWithValue(dueno),
        ],
        child: MaterialApp(
          theme: LavaderoTheme.light(),
          home: const Scaffold(body: PromotionsScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra cada promoción con su franja, estado y resultados', (
    tester,
  ) async {
    await pintar(tester);

    expect(find.text('Mar, Mié · 08:00–11:00'), findsOneWidget);
    expect(find.text('Agotada'), findsOneWidget);
    expect(find.text('50 de 50 usos'), findsOneWidget);
    expect(find.text(r'$81.000'), findsNWidgets(2));
    // Solo 1 vigente: la otra se agotó.
    expect(find.textContaining('promoción vigente'), findsOneWidget);
  });

  testWidgets('el admin de sucursal ve resultados pero no crea ni desactiva', (
    tester,
  ) async {
    await pintar(tester, dueno: false);

    expect(find.text('Nueva promoción'), findsNothing);
    expect(find.text('Desactivar'), findsNothing);
  });

  testWidgets('desactivar pide confirmación antes de llamar al backend', (
    tester,
  ) async {
    when(() => repo.desactivar('p1')).thenAnswer((_) async {});
    await pintar(tester);

    await tester.tap(find.text('Desactivar').first);
    await tester.pumpAndSettle();
    expect(find.text('¿Desactivar "Mañanas de semana"?'), findsOneWidget);
    verifyNever(() => repo.desactivar(any()));

    await tester.tap(find.widgetWithText(FilledButton, 'Desactivar'));
    await tester.pumpAndSettle();
    verify(() => repo.desactivar('p1')).called(1);
  });

  testWidgets('crear un precio por horario envía días y horas', (tester) async {
    when(
      () => repo.crear(
        nombre: any(named: 'nombre'),
        tipo: any(named: 'tipo'),
        tipoDescuento: any(named: 'tipoDescuento'),
        valorDescuento: any(named: 'valorDescuento'),
        vigenteDesde: any(named: 'vigenteDesde'),
        vigenteHasta: any(named: 'vigenteHasta'),
        codigo: any(named: 'codigo'),
        usosMaximos: any(named: 'usosMaximos'),
        dias: any(named: 'dias'),
        horaDesde: any(named: 'horaDesde'),
        horaHasta: any(named: 'horaHasta'),
      ),
    ).thenAnswer((_) async => promo(id: 'p3', nombre: 'Lunes flojos'));
    await pintar(tester);

    await tester.tap(find.text('Nueva promoción'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Lunes flojos',
    );
    await tester.tap(find.text('Lun'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descuento'),
      '15',
    );
    await tester.tap(find.text('Crear promoción'));
    await tester.pumpAndSettle();

    final llamada = verify(
      () => repo.crear(
        nombre: 'Lunes flojos',
        tipo: TipoPromocion.horario,
        tipoDescuento: TipoDescuento.porcentaje,
        valorDescuento: 15,
        vigenteDesde: any(named: 'vigenteDesde'),
        vigenteHasta: any(named: 'vigenteHasta'),
        codigo: any(named: 'codigo'),
        usosMaximos: null,
        dias: captureAny(named: 'dias'),
        horaDesde: '08:00',
        horaHasta: '11:00',
      ),
    );
    llamada.called(1);
    expect(llamada.captured.single, [
      DiaSemana.lunes,
      DiaSemana.martes,
      DiaSemana.miercoles,
    ]);
    expect(find.text('Lunes flojos'), findsOneWidget);
  });

  testWidgets('un porcentaje mayor a 90 no se envía', (tester) async {
    await pintar(tester);

    await tester.tap(find.text('Nueva promoción'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'X');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descuento'),
      '95',
    );
    await tester.tap(find.text('Crear promoción'));
    await tester.pumpAndSettle();

    expect(find.text('Máximo 90 %'), findsOneWidget);
  });
}
