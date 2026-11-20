import 'dart:async';

import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/crm/application/crm_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

class MockCrmRepository extends Mock implements CrmRepository {}

ClienteCrm _cliente(String id) => ClienteCrm(
  id: id,
  nombre: 'Cliente $id',
  email: '$id@example.com',
  visitas: 1,
  gastoTotal: 15000,
  moneda: 'COP',
  vehiculosActivos: 0,
  segmento: SegmentoCliente.nuevo,
);

PaginaClientes _pagina(List<String> ids, {int pagina = 0, int total = 30}) =>
    PaginaClientes(
      clientes: ids.map(_cliente).toList(),
      total: total,
      pagina: pagina,
      tamano: CrmController.tamanoPagina,
      porSegmento: {SegmentoCliente.nuevo: total},
    );

void main() {
  late MockCrmRepository crm;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(OrdenClientes.ultimaVisita));

  Future<PaginaClientes> Function() pedir({
    SegmentoCliente? segmento,
    String? busqueda,
    int pagina = 0,
  }) =>
      () => crm.clientes(
        segmento: segmento,
        busqueda: busqueda ?? any(named: 'busqueda'),
        orden: any(named: 'orden'),
        pagina: pagina,
        tamano: any(named: 'tamano'),
      );

  setUp(() {
    crm = MockCrmRepository();
    when(pedir()).thenAnswer((_) async => _pagina(['a', 'b']));
    container = ProviderContainer(
      overrides: [crmRepositoryProvider.overrideWithValue(crm)],
    );
    addTearDown(container.dispose);
    container.read(crmControllerProvider);
  });

  CrmState estado() => container.read(crmControllerProvider);
  CrmController controller() => container.read(crmControllerProvider.notifier);

  test('carga la primera página al abrir', () async {
    await Future<void>.delayed(Duration.zero);

    expect(estado().clientes.map((c) => c.id), ['a', 'b']);
    expect(estado().hayMas, isTrue);
    expect(estado().isLoading, isFalse);
  });

  test('cargarMas acumula la página siguiente', () async {
    await Future<void>.delayed(Duration.zero);
    when(
      pedir(pagina: 1),
    ).thenAnswer((_) async => _pagina(['c'], pagina: 1, total: 26));

    await controller().cargarMas();

    expect(estado().clientes.map((c) => c.id), ['a', 'b', 'c']);
    expect(estado().pagina, 1);
    expect(estado().hayMas, isFalse);
  });

  test(
    'elegir un segmento vuelve a la primera página con ese filtro',
    () async {
      await Future<void>.delayed(Duration.zero);
      when(
        pedir(segmento: SegmentoCliente.enRiesgo),
      ).thenAnswer((_) async => _pagina(['r']));

      await controller().elegirSegmento(SegmentoCliente.enRiesgo);

      expect(estado().segmento, SegmentoCliente.enRiesgo);
      expect(estado().clientes.single.id, 'r');
      expect(estado().pagina, 0);
    },
  );

  test('una respuesta vieja no pisa una búsqueda más nueva', () async {
    await Future<void>.delayed(Duration.zero);
    final lenta = Completer<PaginaClientes>();
    when(pedir(busqueda: 'an')).thenAnswer((_) => lenta.future);
    when(pedir(busqueda: 'ana')).thenAnswer((_) async => _pagina(['ana']));

    final primera = controller().buscar('an');
    await controller().buscar('ana');
    lenta.complete(_pagina(['viejo']));
    await primera;

    expect(estado().clientes.single.id, 'ana');
  });

  test('un error queda en el estado sin perder la lista', () async {
    await Future<void>.delayed(Duration.zero);
    when(
      pedir(pagina: 1),
    ).thenThrow(const ApiException(message: 'Servidor caído', statusCode: 500));

    await controller().cargarMas();

    expect(estado().errorMessage, 'Servidor caído');
    expect(estado().clientes, hasLength(2));
    expect(estado().isLoadingMore, isFalse);
  });
}
