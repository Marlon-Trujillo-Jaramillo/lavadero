import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/subscription/application/subscription_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockTenantRepository extends Mock implements TenantRepository {}

class MockPagoRepository extends Mock implements PagoRepository {}

void main() {
  late MockTenantRepository tenantRepository;
  late MockPagoRepository pagoRepository;
  late List<Uri> abiertas;
  late bool abrirOk;
  Object? errorAlAbrir;
  late ProviderContainer container;

  const basico = SubscriptionPlan(
    id: 'p1',
    nombre: 'Básico',
    precio: 49000,
    moneda: 'COP',
    maxSucursales: 1,
    maxEmpleados: 3,
    features: [],
  );
  const pro = SubscriptionPlan(
    id: 'p2',
    nombre: 'Pro',
    precio: 99000,
    moneda: 'COP',
    maxSucursales: 3,
    maxEmpleados: 10,
    features: ['Reportes'],
  );
  final pago = Pago(
    id: 'g1',
    subscriptionPlanId: 'p2',
    monto: 99000,
    moneda: 'COP',
    referencia: 'REF-1',
    estado: PagoEstado.pendiente,
    creadoEn: DateTime(2026, 10, 1),
  );
  const checkout = CheckoutPago(
    pagoId: 'g1',
    urlCheckout: 'https://checkout.wompi.co/p/',
    llavePublica: 'pub_test',
    referencia: 'REF-1',
    montoEnCentavos: 9900000,
    moneda: 'COP',
    firmaIntegridad: 'firma',
  );

  setUp(() async {
    tenantRepository = MockTenantRepository();
    pagoRepository = MockPagoRepository();
    abiertas = [];
    abrirOk = true;
    errorAlAbrir = null;
    when(() => tenantRepository.listarPlanesDisponibles()).thenAnswer((_) async => const [pro, basico]);
    when(() => pagoRepository.listar()).thenAnswer((_) async => [pago]);

    container = ProviderContainer(
      overrides: [
        tenantRepositoryProvider.overrideWithValue(tenantRepository),
        pagoRepositoryProvider.overrideWithValue(pagoRepository),
        abrirUrlExternaProvider.overrideWithValue((uri) async {
          abiertas.add(uri);
          if (errorAlAbrir != null) throw errorAlAbrir!;
          return abrirOk;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.read(subscriptionControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('carga planes (ordenados por precio) e historial de pagos', () {
    final state = container.read(subscriptionControllerProvider);
    expect(state.planes, [basico, pro]);
    expect(state.pagos, [pago]);
    expect(state.cargandoPlanes, isFalse);
    expect(state.cargandoPagos, isFalse);
  });

  test('pagar() abre el checkout de Wompi y recarga el historial', () async {
    when(
      () => pagoRepository.iniciarPagoSuscripcion(subscriptionPlanId: 'p2'),
    ).thenAnswer((_) async => checkout);

    await container.read(subscriptionControllerProvider.notifier).pagar('p2');

    expect(abiertas.single.host, 'checkout.wompi.co');
    expect(abiertas.single.queryParameters['reference'], 'REF-1');
    verify(() => pagoRepository.listar()).called(2);
    final state = container.read(subscriptionControllerProvider);
    expect(state.pagandoPlanId, isNull);
    expect(state.errorPago, isNull);
  });

  test('un 400 de pasarela no configurada se muestra con un mensaje amigable', () async {
    when(() => pagoRepository.iniciarPagoSuscripcion(subscriptionPlanId: 'p2')).thenThrow(
      const ApiException(
        message: 'Los pagos todavía no están configurados en este ambiente (falta la cuenta de Wompi)',
        statusCode: 400,
      ),
    );

    await container.read(subscriptionControllerProvider.notifier).pagar('p2');

    final state = container.read(subscriptionControllerProvider);
    expect(state.errorPago, SubscriptionController.mensajePasarelaNoConfigurada);
    expect(state.pagandoPlanId, isNull);
    expect(abiertas, isEmpty);
  });

  test('si el navegador bloquea la pestaña, se ofrece reabrir el checkout', () async {
    abrirOk = false;
    when(
      () => pagoRepository.iniciarPagoSuscripcion(subscriptionPlanId: 'p2'),
    ).thenAnswer((_) async => checkout);

    await container.read(subscriptionControllerProvider.notifier).pagar('p2');
    expect(
      container.read(subscriptionControllerProvider).errorPago,
      SubscriptionController.mensajeCheckoutBloqueado,
    );

    abrirOk = true;
    await container.read(subscriptionControllerProvider.notifier).reabrirCheckout();
    expect(container.read(subscriptionControllerProvider).errorPago, isNull);
    expect(abiertas, hasLength(2));
  });

  test('un 403 al listar planes no rompe el historial', () async {
    when(
      () => tenantRepository.listarPlanesDisponibles(),
    ).thenThrow(const ApiException(message: 'Forbidden', statusCode: 403));

    await container.read(subscriptionControllerProvider.notifier).cargarPlanes();

    final state = container.read(subscriptionControllerProvider);
    expect(state.errorPlanes, SubscriptionController.mensajePlanesSinPermiso);
    expect(state.pagos, [pago]);
  });

  test('si url_launcher lanza, se muestra el aviso amigable y el botón se libera', () async {
    errorAlAbrir = Exception('PlatformException(ACTIVITY_NOT_FOUND)');
    when(
      () => pagoRepository.iniciarPagoSuscripcion(subscriptionPlanId: 'p2'),
    ).thenAnswer((_) async => checkout);

    await container.read(subscriptionControllerProvider.notifier).pagar('p2');

    final state = container.read(subscriptionControllerProvider);
    expect(state.errorPago, SubscriptionController.mensajeCheckoutBloqueado);
    expect(state.pagandoPlanId, isNull);
    expect(state.ultimoCheckout, checkout);
  });

  test('un pago nuevo descarta el checkout anterior', () async {
    when(
      () => pagoRepository.iniciarPagoSuscripcion(subscriptionPlanId: 'p2'),
    ).thenAnswer((_) async => checkout);
    await container.read(subscriptionControllerProvider.notifier).pagar('p2');
    expect(container.read(subscriptionControllerProvider).ultimoCheckout, checkout);

    when(() => pagoRepository.iniciarPagoSuscripcion(subscriptionPlanId: 'p1')).thenThrow(
      const ApiException(message: 'El plan no requiere pago', statusCode: 400),
    );
    await container.read(subscriptionControllerProvider.notifier).pagar('p1');
    expect(container.read(subscriptionControllerProvider).ultimoCheckout, isNull);
  });
}
