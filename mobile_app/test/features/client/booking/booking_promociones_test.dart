import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/client/booking/application/booking_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockSchedulingRepository extends Mock implements SchedulingRepository {}

class MockVehiculoRepository extends Mock implements VehiculoRepository {}

class MockPromocionRepository extends Mock implements PromocionRepository {}

/// Cotización con promociones y cupón en el flujo de reservar (spec 011).
void main() {
  late MockSchedulingRepository scheduling;
  late MockPromocionRepository promociones;
  late ProviderContainer container;

  final inicio = DateTime.utc(2026, 11, 24, 14);
  final otraHora = DateTime.utc(2026, 11, 24, 20);

  Cotizacion cotizacion({num descuento = 0, String? promocion}) => Cotizacion(
    precioLista: 45000,
    descuento: descuento,
    precioFinal: 45000 - descuento,
    moneda: 'COP',
    promocionId: promocion == null ? null : 'p-$promocion',
    promocionNombre: promocion,
  );

  Future<Cotizacion> Function() cotizar(DateTime hora, {String? cupon}) =>
      () => promociones.cotizar(
        servicioId: 's1',
        fechaHoraInicio: hora,
        cupon: cupon,
      );

  BookingState estado() => container.read(bookingControllerProvider);
  BookingController controller() =>
      container.read(bookingControllerProvider.notifier);

  setUp(() async {
    final catalog = MockCatalogRepository();
    scheduling = MockSchedulingRepository();
    final vehiculos = MockVehiculoRepository();
    promociones = MockPromocionRepository();
    when(() => catalog.listarActivos()).thenAnswer((_) async => []);
    when(() => scheduling.listarSucursales()).thenAnswer((_) async => []);
    when(() => vehiculos.misVehiculos()).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(catalog),
        schedulingRepositoryProvider.overrideWithValue(scheduling),
        vehiculoRepositoryProvider.overrideWithValue(vehiculos),
        promocionRepositoryProvider.overrideWithValue(promociones),
      ],
    );
    addTearDown(container.dispose);
    container.read(bookingControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('cotizar trae el precio por horario y se limpia sin hora', () async {
    when(cotizar(inicio)).thenAnswer(
      (_) async => cotizacion(descuento: 9000, promocion: 'Mañanas'),
    );

    await controller().cotizar(servicioId: 's1', fechaHoraInicio: inicio);
    expect(estado().cotizacion?.precioFinal, 36000);

    await controller().cotizar(servicioId: 's1', fechaHoraInicio: null);
    expect(estado().cotizacion, isNull);
  });

  test('una cotización vieja no pisa la de la hora nueva', () async {
    final lenta = Completer<Cotizacion>();
    when(cotizar(inicio)).thenAnswer((_) => lenta.future);
    when(cotizar(otraHora)).thenAnswer((_) async => cotizacion());

    final primera = controller().cotizar(
      servicioId: 's1',
      fechaHoraInicio: inicio,
    );
    await controller().cotizar(servicioId: 's1', fechaHoraInicio: otraHora);
    lenta.complete(cotizacion(descuento: 9000, promocion: 'Mañanas'));
    await primera;

    expect(estado().cotizacion?.tieneDescuento, isFalse);
  });

  test('un cupón inválido muestra el motivo y no se aplica', () async {
    when(cotizar(inicio, cupon: 'NOPE')).thenThrow(
      const ApiException(
        message: "El cupón 'NOPE' no existe o ya no está activo",
        statusCode: 400,
      ),
    );

    await controller().aplicarCupon(
      codigo: 'NOPE',
      servicioId: 's1',
      fechaHoraInicio: inicio,
    );

    expect(estado().cupon, isNull);
    expect(estado().cuponError, contains('NOPE'));
    expect(estado().isAplicandoCupon, isFalse);
  });

  test('un cupón válido se guarda y se envía al reservar', () async {
    when(cotizar(inicio, cupon: 'hola10')).thenAnswer(
      (_) async => cotizacion(descuento: 4500, promocion: 'Bienvenida'),
    );
    final reserva = Reserva(
      id: 'r1',
      sucursalId: 'suc1',
      servicioId: 's1',
      clienteId: 'c1',
      fechaHoraInicio: inicio,
      fechaHoraFin: inicio.add(const Duration(minutes: 30)),
      duracionEstimadaMinutos: 30,
      precio: 40500,
      moneda: 'COP',
      estado: ReservaEstado.pendiente,
      promocionId: 'p-Bienvenida',
      precioLista: 45000,
    );
    when(
      () => scheduling.crear(
        sucursalId: 'suc1',
        servicioId: 's1',
        fechaHoraInicio: inicio,
        vehiculoId: any(named: 'vehiculoId'),
        codigoCupon: 'HOLA10',
      ),
    ).thenAnswer((_) async => reserva);

    await controller().aplicarCupon(
      codigo: 'hola10',
      servicioId: 's1',
      fechaHoraInicio: inicio,
    );
    await controller().reservar(
      sucursalId: 'suc1',
      servicioId: 's1',
      fechaHoraInicio: inicio,
    );

    expect(estado().cupon, 'HOLA10');
    expect(estado().reservaCreada?.descuento, 4500);
  });

  test(
    'si el cupón deja de servir al cambiar de hora, se quita y se explica',
    () async {
      when(cotizar(inicio, cupon: 'hola10')).thenAnswer(
        (_) async => cotizacion(descuento: 4500, promocion: 'Bienvenida'),
      );
      when(cotizar(otraHora, cupon: 'HOLA10')).thenThrow(
        const ApiException(
          message: "La promoción 'Bienvenida' venció el 2026-11-23",
          statusCode: 400,
        ),
      );
      when(cotizar(otraHora)).thenAnswer((_) async => cotizacion());

      await controller().aplicarCupon(
        codigo: 'hola10',
        servicioId: 's1',
        fechaHoraInicio: inicio,
      );
      await controller().cotizar(servicioId: 's1', fechaHoraInicio: otraHora);

      expect(estado().cupon, isNull);
      expect(estado().cuponError, contains('venció'));
      expect(estado().cotizacion?.precioFinal, 45000);
    },
  );
}
