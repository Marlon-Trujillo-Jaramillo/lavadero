import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late InventarioRepository repository;

  setUpAll(() => registerFallbackValue(FakeRequestOptions()));

  setUp(() {
    adapter = MockHttpClientAdapter();
    final dio = Dio(
      BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'),
    )..httpClientAdapter = adapter;
    repository = InventarioRepository(dio: dio);
  });

  RequestOptions ultimaPeticion() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.last
          as RequestOptions;

  test('insumos lee el stock de la sucursal y su valor en bodega', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody([
        {
          'id': 'i-1',
          'nombre': 'Shampoo',
          'unidad': 'ML',
          'costoUnitario': 12.5,
          'moneda': 'COP',
          'sucursalId': 's-1',
          'cantidad': 400.000,
          'minimo': 500,
          'bajoMinimo': true,
        },
      ], 200),
    );

    final insumo = (await repository.insumos(sucursalId: 's-1')).single;

    expect(ultimaPeticion().queryParameters, {'sucursalId': 's-1'});
    expect(insumo.unidad, UnidadMedida.ml);
    expect(insumo.bajoMinimo, isTrue);
    expect(insumo.valorEnBodega, 5000);
  });

  test('un conteo físico va a /ajustes con la cantidad contada', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({
        'id': 'm-1',
        'tipo': 'AJUSTE',
        'cantidad': -70,
        'saldo': 430,
        'reservaId': null,
        'nota': 'Conteo semanal',
        'creadoEn': '2026-11-20T15:00:00Z',
      }, 200),
    );

    final movimiento = await repository.ajustar(
      insumoId: 'i-1',
      sucursalId: 's-1',
      cantidadContada: 430,
      nota: ' Conteo semanal ',
    );

    final peticion = ultimaPeticion();
    expect(peticion.path, '/inventario/insumos/i-1/ajustes');
    expect(peticion.data, {
      'sucursalId': 's-1',
      'cantidad': 430,
      'nota': 'Conteo semanal',
    });
    expect(movimiento.tipo, TipoMovimiento.ajuste);
  });

  test('definirReceta envía cada insumo con su cantidad', () async {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer((_) async => ResponseBody.fromString('', 204));

    await repository.definirReceta(
      servicioId: 'srv-1',
      lineas: {'i-1': 40, 'i-2': 25},
    );

    final peticion = ultimaPeticion();
    expect(peticion.method, 'PUT');
    expect(peticion.data, {
      'lineas': [
        {'insumoId': 'i-1', 'cantidad': 40},
        {'insumoId': 'i-2', 'cantidad': 25},
      ],
    });
  });

  test('costos lee la receta, el costo y el margen', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody([
        {
          'servicioId': 'srv-1',
          'nombre': 'Lavado full',
          'activo': true,
          'precio': 45000,
          'moneda': 'COP',
          'lineas': [
            {
              'insumoId': 'i-1',
              'insumo': 'Shampoo',
              'unidad': 'ML',
              'cantidad': 40,
              'costo': 500,
            },
          ],
          'costoInsumos': 500,
          'margen': 44500,
          'margenPorcentaje': 99,
        },
      ], 200),
    );

    final costo = (await repository.costos()).single;

    expect(costo.tieneReceta, isTrue);
    expect(costo.margenPorcentaje, 99);
    expect(costo.lineas.single.unidad, UnidadMedida.ml);
  });
}
