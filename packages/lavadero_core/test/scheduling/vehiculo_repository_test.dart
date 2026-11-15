import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late VehiculoRepository repository;

  final vehiculoJson = {
    'id': 'v-1',
    'placa': 'ABC123',
    'tipo': 'CAMIONETA',
    'marca': 'Mazda',
    'color': null,
    'creadoEn': '2026-11-15T10:00:00Z',
  };

  setUpAll(() => registerFallbackValue(FakeRequestOptions()));

  setUp(() {
    adapter = MockHttpClientAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'))
      ..httpClientAdapter = adapter;
    repository = VehiculoRepository(dio: dio);
  });

  RequestOptions ultimaPeticion() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.last
          as RequestOptions;

  test('misVehiculos lee la lista y arma la descripción', () async {
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => jsonResponseBody([vehiculoJson], 200));

    final vehiculos = await repository.misVehiculos();

    expect(vehiculos.single.placa, 'ABC123');
    expect(vehiculos.single.tipo, TipoVehiculo.camioneta);
    expect(vehiculos.single.descripcion, 'Camioneta · Mazda');
    expect(ultimaPeticion().path, '/vehiculos/mios');
  });

  test('registrar no envía marca ni color vacíos', () async {
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => jsonResponseBody(vehiculoJson, 201));

    await repository.registrar(
      placa: 'abc-123',
      tipo: TipoVehiculo.camioneta,
      marca: ' ',
    );

    expect(ultimaPeticion().data, {'placa': 'abc-123', 'tipo': 'CAMIONETA'});
  });

  test('archivar llama a DELETE con el id', () async {
    when(() => adapter.fetch(any(), any(), any()))
        .thenAnswer((_) async => jsonResponseBody(null, 204));

    await repository.archivar('v-1');

    final peticion = ultimaPeticion();
    expect(peticion.method, 'DELETE');
    expect(peticion.path, '/vehiculos/v-1');
  });

  test('una placa repetida llega como ApiException con el mensaje del backend',
      () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody(
        errorBody(
          status: 400,
          error: 'Bad Request',
          message: 'Ya tienes un vehículo con la placa ABC123',
          path: '/api/v1/vehiculos',
        ),
        400,
      ),
    );

    await expectLater(
      repository.registrar(placa: 'ABC123', tipo: TipoVehiculo.automovil),
      throwsA(isA<ApiException>().having(
          (e) => e.message, 'message', contains('ABC123'))),
    );
  });

  test('una reserva trae la placa del vehículo elegido', () {
    final reserva = Reserva.fromJson({
      'id': 'r-1',
      'sucursalId': 's-1',
      'servicioId': 'sv-1',
      'clienteId': 'c-1',
      'fechaHoraInicio': '2026-12-01T15:00:00Z',
      'fechaHoraFin': '2026-12-01T15:30:00Z',
      'duracionEstimadaMinutos': 30,
      'precio': 25000,
      'moneda': 'COP',
      'estado': 'PENDIENTE',
      'vehiculoId': 'v-1',
      'vehiculoPlaca': 'ABC123',
    });
    expect(reserva.vehiculoPlaca, 'ABC123');
  });
}
