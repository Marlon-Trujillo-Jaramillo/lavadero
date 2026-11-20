import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late CrmRepository repository;

  final clienteJson = {
    'id': 'c-1',
    'nombre': 'Ana Gómez',
    'email': 'ana@example.com',
    'visitas': 3,
    'gastoTotal': 45000.00,
    'moneda': 'COP',
    'primeraVisita': '2026-09-01T15:00:00Z',
    'ultimaVisita': '2026-10-01T15:00:00Z',
    'proximaReserva': null,
    'vehiculosActivos': 1,
    'segmento': 'EN_RIESGO',
  };

  setUpAll(() => registerFallbackValue(FakeRequestOptions()));

  setUp(() {
    adapter = MockHttpClientAdapter();
    final dio = Dio(
      BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'),
    )..httpClientAdapter = adapter;
    repository = CrmRepository(dio: dio);
  });

  RequestOptions ultimaPeticion() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.last
          as RequestOptions;

  test(
    'clientes envía filtros y lee la página con el conteo por segmento',
    () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody({
          'clientes': [clienteJson],
          'total': 30,
          'pagina': 0,
          'tamano': 25,
          'porSegmento': {'EN_RIESGO': 30, 'NUEVO': 4},
        }, 200),
      );

      final pagina = await repository.clientes(
        segmento: SegmentoCliente.enRiesgo,
        busqueda: '  ana ',
        orden: OrdenClientes.gasto,
      );

      final peticion = ultimaPeticion();
      expect(peticion.path, '/crm/clientes');
      expect(peticion.queryParameters, {
        'segmento': 'EN_RIESGO',
        'q': 'ana',
        'orden': 'GASTO',
        'pagina': 0,
        'tamano': 25,
      });
      final ana = pagina.clientes.single;
      expect(ana.segmento, SegmentoCliente.enRiesgo);
      expect(ana.gastoTotal, 45000);
      expect(ana.proximaReserva, isNull);
      expect(ana.diasSinVenir(ahora: DateTime.utc(2026, 11, 20, 15)), 50);
      expect(pagina.porSegmento[SegmentoCliente.frecuente], 0);
      expect(pagina.totalClientes, 34);
      expect(pagina.hayMas, isTrue);
    },
  );

  test('sin búsqueda ni segmento no los envía', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({
        'clientes': <dynamic>[],
        'total': 0,
        'pagina': 0,
        'tamano': 25,
        'porSegmento': <String, dynamic>{},
      }, 200),
    );

    await repository.clientes(busqueda: '   ');

    expect(
      ultimaPeticion().queryParameters.keys,
      unorderedEquals(['orden', 'pagina', 'tamano']),
    );
  });

  test('ficha lee vehículos e historial', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({
        'cliente': clienteJson,
        'servicioFavorito': 'Lavado',
        'vehiculos': [
          {
            'id': 'v-1',
            'placa': 'ABC123',
            'tipo': 'AUTOMOVIL',
            'marca': null,
            'color': null,
            'creadoEn': '2026-09-01T15:00:00Z',
          },
        ],
        'historial': [
          {
            'reservaId': 'r-1',
            'fecha': '2026-10-01T15:00:00Z',
            'servicio': 'Lavado',
            'sucursal': 'Principal',
            'estado': 'COMPLETADA',
            'precio': 15000,
            'moneda': 'COP',
            'placa': 'ABC123',
          },
        ],
      }, 200),
    );

    final ficha = await repository.ficha('c-1');

    expect(ultimaPeticion().path, '/crm/clientes/c-1');
    expect(ficha.servicioFavorito, 'Lavado');
    expect(ficha.vehiculos.single.placa, 'ABC123');
    expect(ficha.historial.single.estado, ReservaEstado.completada);
  });

  test('un 404 se traduce a ApiException', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({'message': 'Cliente no encontrado'}, 404),
    );

    expect(() => repository.ficha('x'), throwsA(isA<ApiException>()));
  });
}
