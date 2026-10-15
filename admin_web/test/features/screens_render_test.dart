import 'dart:async';

import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/agenda/agenda_screen.dart';
import 'package:admin_web/features/branches/branches_screen.dart';
import 'package:admin_web/features/catalog_pricing/catalog_pricing_screen.dart';
import 'package:admin_web/features/crm/crm_screen.dart';
import 'package:admin_web/features/employees/employees_screen.dart';
import 'package:admin_web/features/reports/reports_screen.dart';
import 'package:admin_web/features/subscription/subscription_screen.dart';
import 'package:admin_web/features/tenant_admin/tenant_admin_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockEmpleadoRepository extends Mock implements EmpleadoRepository {}

class MockTenantRepository extends Mock implements TenantRepository {}

class MockPagoRepository extends Mock implements PagoRepository {}

/// Pinta cada pantalla del panel con datos de ejemplo, en ancho de escritorio y en angosto, para
/// detectar errores de layout (overflow, viewports sin alto, intrínsecos) que los tests de
/// controller no ven.
void main() {
  final hoy = DateTime.now();
  const sucursal = Sucursal(
    id: 'b1',
    nombre: 'Sede Centro',
    direccion: 'Calle 10 # 5-20',
    capacidadSimultanea: 3,
  );
  const servicio = ServiceItem(
    id: 's1',
    nombre: 'Lavado full',
    descripcion: 'Exterior, interior y aspirado',
    duracionEstimadaMinutos: 45,
    precio: 45000,
    moneda: 'COP',
    activo: true,
  );
  const servicioInactivo = ServiceItem(
    id: 's2',
    nombre: 'Polichado',
    duracionEstimadaMinutos: 120,
    precio: 150000,
    moneda: 'COP',
    activo: false,
  );
  Reserva reserva(String id, int hora, ReservaEstado estado) => Reserva(
    id: id,
    sucursalId: 'b1',
    servicioId: 's1',
    clienteId: 'c1',
    fechaHoraInicio: DateTime(hoy.year, hoy.month, hoy.day, hora),
    fechaHoraFin: DateTime(hoy.year, hoy.month, hoy.day, hora, 45),
    duracionEstimadaMinutos: 45,
    precio: 45000,
    moneda: 'COP',
    estado: estado,
  );
  const planes = [
    SubscriptionPlan(
      id: 'p1',
      nombre: 'Básico',
      precio: 49000,
      moneda: 'COP',
      maxSucursales: 1,
      maxEmpleados: 3,
      features: ['Agenda', 'Catálogo'],
    ),
    SubscriptionPlan(
      id: 'p2',
      nombre: 'Pro',
      precio: 99000,
      moneda: 'COP',
      maxSucursales: 3,
      maxEmpleados: 10,
      features: ['Agenda', 'Catálogo', 'Reportes avanzados'],
    ),
    SubscriptionPlan(
      id: 'p3',
      nombre: 'Empresa',
      precio: 199000,
      moneda: 'COP',
      maxSucursales: 10,
      maxEmpleados: 50,
      features: [],
    ),
  ];

  late MockSchedulingRepository scheduling;
  late MockCatalogRepository catalog;
  late MockEmpleadoRepository empleados;
  late MockTenantRepository tenants;
  late MockPagoRepository pagos;

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    scheduling = MockSchedulingRepository();
    catalog = MockCatalogRepository();
    empleados = MockEmpleadoRepository();
    tenants = MockTenantRepository();
    pagos = MockPagoRepository();
    when(() => scheduling.listarSucursales()).thenAnswer((_) async => const [sucursal]);
    when(
      () => scheduling.agendaDelDia(
        sucursalId: any(named: 'sucursalId'),
        fecha: any(named: 'fecha'),
      ),
    ).thenAnswer(
      (_) async => [
        reserva('r1', 9, ReservaEstado.completada),
        reserva('r2', 9, ReservaEstado.enProgreso),
        reserva('r3', 11, ReservaEstado.pendiente),
        reserva('r4', 15, ReservaEstado.cancelada),
      ],
    );
    when(
      () => scheduling.resumenVentas(
        desde: any(named: 'desde'),
        hasta: any(named: 'hasta'),
      ),
    ).thenAnswer(
      (_) async => const ResumenVentas(
        ingresosTotales: 1250000,
        moneda: 'COP',
        totalReservasCompletadas: 28,
        serviciosMasPedidos: [ServicioPopular(servicioId: 's1', nombreServicio: 'Lavado full', cantidad: 20)],
      ),
    );
    when(() => catalog.listar()).thenAnswer((_) async => const [servicio, servicioInactivo]);
    when(() => empleados.listar()).thenAnswer(
      (_) async => const [
        Empleado(id: 'e1', email: 'ana@lavadero.co', nombre: 'Ana Gómez', sucursalId: 'b1', estado: 'ACTIVO'),
        Empleado(id: 'e2', email: 'luis@lavadero.co', nombre: 'Luis Pérez', estado: 'BLOQUEADO'),
      ],
    );
    when(() => tenants.listarPlanes()).thenAnswer((_) async => planes);
    when(() => tenants.listarPlanesDisponibles()).thenAnswer((_) async => planes);
    when(() => tenants.search(any())).thenAnswer(
      (_) async => const [TenantSummary(id: 't1', slug: 'lavadero-centro', nombre: 'Lavadero Centro')],
    );
    when(() => pagos.listar()).thenAnswer(
      (_) async => [
        Pago(
          id: 'g1',
          subscriptionPlanId: 'p2',
          monto: 99000,
          moneda: 'COP',
          referencia: 'LAV-123',
          estado: PagoEstado.aprobado,
          creadoEn: DateTime(2026, 9, 1, 10),
        ),
      ],
    );
  });

  Future<void> pintar(WidgetTester tester, Widget screen, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          schedulingRepositoryProvider.overrideWithValue(scheduling),
          catalogRepositoryProvider.overrideWithValue(catalog),
          empleadoRepositoryProvider.overrideWithValue(empleados),
          tenantRepositoryProvider.overrideWithValue(tenants),
          pagoRepositoryProvider.overrideWithValue(pagos),
          abrirUrlExternaProvider.overrideWithValue((_) async => true),
        ],
        child: MaterialApp(
          theme: LavaderoTheme.light(),
          home: Scaffold(body: screen),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  }

  const tamanios = {'escritorio': Size(1440, 1000), 'angosto': Size(700, 1000)};

  final pantallas = <String, (Widget, String)>{
    'agenda': (const AgendaScreen(), 'Iniciar'),
    'empleados': (const EmployeesScreen(), 'Ana Gómez'),
    'sucursales': (const BranchesScreen(), 'Sede Centro'),
    'catálogo': (const CatalogPricingScreen(), r'$45.000'),
    'reportes': (const ReportsScreen(), '7 días'),
    'tenants': (const TenantAdminScreen(), 'Planes de suscripción'),
    'suscripción': (const SubscriptionScreen(), 'Pagar con Wompi'),
    'crm': (const CrmScreen(), 'Próximamente'),
  };

  for (final pantalla in pantallas.entries) {
    for (final tamanio in tamanios.entries) {
      testWidgets('${pantalla.key} se pinta sin errores (${tamanio.key})', (tester) async {
        await pintar(tester, pantalla.value.$1, tamanio.value);
        expect(tester.takeException(), isNull);
        expect(find.text(pantalla.value.$2), findsWidgets);
      });
    }
  }

  for (final pantalla in pantallas.entries) {
    testWidgets('${pantalla.key} muestra su estado de carga sin errores', (tester) async {
      final nunca = Completer<Never>().future;
      when(() => scheduling.listarSucursales()).thenAnswer((_) => nunca);
      when(
        () => scheduling.resumenVentas(desde: any(named: 'desde'), hasta: any(named: 'hasta')),
      ).thenAnswer((_) => nunca);
      when(() => catalog.listar()).thenAnswer((_) => nunca);
      when(() => empleados.listar()).thenAnswer((_) => nunca);
      when(() => tenants.listarPlanes()).thenAnswer((_) => nunca);
      when(() => tenants.listarPlanesDisponibles()).thenAnswer((_) => nunca);
      when(() => tenants.search(any())).thenAnswer((_) => nunca);
      when(() => pagos.listar()).thenAnswer((_) => nunca);

      await pintar(tester, pantalla.value.$1, tamanios['escritorio']!);
      expect(tester.takeException(), isNull);
    });

    testWidgets('${pantalla.key} muestra su error sin errores de layout', (tester) async {
      const fallo = ApiException(message: 'Servidor caído', statusCode: 500);
      when(() => scheduling.listarSucursales()).thenThrow(fallo);
      when(
        () => scheduling.resumenVentas(desde: any(named: 'desde'), hasta: any(named: 'hasta')),
      ).thenThrow(fallo);
      when(() => catalog.listar()).thenThrow(fallo);
      when(() => empleados.listar()).thenThrow(fallo);
      when(() => tenants.listarPlanes()).thenThrow(fallo);
      when(() => tenants.listarPlanesDisponibles()).thenThrow(fallo);
      when(() => tenants.search(any())).thenThrow(fallo);
      when(() => pagos.listar()).thenThrow(fallo);

      await pintar(tester, pantalla.value.$1, tamanios['angosto']!);
      expect(tester.takeException(), isNull);
      if (pantalla.key != 'crm') expect(find.text('Servidor caído'), findsWidgets);
    });
  }

  testWidgets('agenda: cancelar pide confirmación antes de llamar al backend', (tester) async {
    await pintar(tester, const AgendaScreen(), tamanios['escritorio']!);
    await tester.tap(find.byTooltip('Cancelar reserva'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cancelar esta reserva?'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    verifyNever(() => scheduling.cancelar(any()));
  });

  testWidgets('suscripción: "Pagar con Wompi" inicia el pago del plan', (tester) async {
    when(() => pagos.iniciarPagoSuscripcion(subscriptionPlanId: any(named: 'subscriptionPlanId')))
        .thenAnswer(
          (_) async => const CheckoutPago(
            pagoId: 'g2',
            urlCheckout: 'https://checkout.wompi.co/p/',
            llavePublica: 'pub',
            referencia: 'LAV-2',
            montoEnCentavos: 4900000,
            moneda: 'COP',
            firmaIntegridad: 'f',
          ),
        );
    await pintar(tester, const SubscriptionScreen(), tamanios['escritorio']!);
    await tester.tap(find.text('Pagar con Wompi').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => pagos.iniciarPagoSuscripcion(subscriptionPlanId: 'p1')).called(1);
  });
}
