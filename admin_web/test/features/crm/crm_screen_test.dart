import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/crm/crm_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockCrmRepository extends Mock implements CrmRepository {}

void main() {
  late MockCrmRepository crm;
  final abiertas = <Uri>[];
  final hoy = DateTime.now();

  final laura = ClienteCrm(
    id: 'c1',
    nombre: 'Laura Ríos',
    email: 'laura@example.com',
    visitas: 5,
    gastoTotal: 225000,
    moneda: 'COP',
    primeraVisita: hoy.subtract(const Duration(days: 150)),
    ultimaVisita: hoy.subtract(const Duration(days: 70)),
    vehiculosActivos: 1,
    segmento: SegmentoCliente.enRiesgo,
  );

  setUpAll(() => registerFallbackValue(OrdenClientes.ultimaVisita));

  setUp(() {
    abiertas.clear();
    crm = MockCrmRepository();
    when(
      () => crm.clientes(
        segmento: any(named: 'segmento'),
        busqueda: any(named: 'busqueda'),
        orden: any(named: 'orden'),
        pagina: any(named: 'pagina'),
        tamano: any(named: 'tamano'),
      ),
    ).thenAnswer(
      (_) async => PaginaClientes(
        clientes: [laura],
        total: 1,
        pagina: 0,
        tamano: 25,
        porSegmento: const {SegmentoCliente.enRiesgo: 1},
      ),
    );
    when(() => crm.ficha('c1')).thenAnswer(
      (_) async => FichaCliente(
        cliente: laura,
        servicioFavorito: 'Lavado full',
        vehiculos: [
          Vehiculo(
            id: 'v1',
            placa: 'ABC123',
            tipo: TipoVehiculo.automovil,
            marca: 'Mazda',
            creadoEn: hoy,
          ),
        ],
        historial: [
          VisitaCliente(
            reservaId: 'r1',
            fecha: hoy.subtract(const Duration(days: 70)),
            servicio: 'Lavado full',
            sucursal: 'Sede Centro',
            estado: ReservaEstado.completada,
            precio: 45000,
            moneda: 'COP',
            placa: 'ABC123',
          ),
        ],
      ),
    );
  });

  Future<void> pintar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          crmRepositoryProvider.overrideWithValue(crm),
          abrirUrlExternaProvider.overrideWithValue((uri) async {
            abiertas.add(uri);
            return true;
          }),
        ],
        child: MaterialApp(
          theme: LavaderoTheme.light(),
          home: const Scaffold(body: CrmScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('la ficha muestra vehículos e historial y sugiere el correo', (
    tester,
  ) async {
    await pintar(tester);
    expect(find.text('Hace 70 días'), findsOneWidget);

    await tester.tap(find.text('Laura Ríos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('ABC123 · Automóvil'), findsOneWidget);
    expect(find.textContaining('Sede Centro'), findsOneWidget);

    await tester.tap(find.text('Escribirle'));
    await tester.pumpAndSettle();

    final correo = abiertas.single;
    expect(correo.scheme, 'mailto');
    expect(correo.path, 'laura@example.com');
    expect(Uri.decodeComponent(correo.query), contains('Te extrañamos, Laura'));
  });

  testWidgets('el aviso de clientes en riesgo filtra por ese segmento', (
    tester,
  ) async {
    await pintar(tester);

    await tester.tap(find.text('Ver'));
    await tester.pumpAndSettle();

    verify(
      () => crm.clientes(
        segmento: SegmentoCliente.enRiesgo,
        busqueda: any(named: 'busqueda'),
        orden: any(named: 'orden'),
        pagina: 0,
        tamano: any(named: 'tamano'),
      ),
    ).called(1);
  });
}
