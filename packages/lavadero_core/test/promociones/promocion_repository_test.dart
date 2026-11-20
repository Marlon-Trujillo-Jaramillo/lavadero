import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late PromocionRepository repository;

  final horarioJson = {
    'id': 'p-1',
    'nombre': 'Mañanas de martes',
    'tipo': 'HORARIO',
    'codigo': null,
    'tipoDescuento': 'PORCENTAJE',
    'valorDescuento': 20.00,
    'moneda': null,
    'dias': ['TUESDAY', 'WEDNESDAY'],
    'horaDesde': '08:00:00',
    'horaHasta': '11:00:00',
    'vigenteDesde': '2026-11-01',
    'vigenteHasta': '2026-12-31',
    'usosMaximos': null,
    'usos': 12,
    'activa': true,
    'creadaEn': '2026-11-01T10:00:00Z',
    'reservas': 12,
    'completadas': 9,
    'ingresos': 324000,
    'descuentoOtorgado': 81000,
  };

  setUpAll(() => registerFallbackValue(FakeRequestOptions()));

  setUp(() {
    adapter = MockHttpClientAdapter();
    final dio = Dio(
      BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'),
    )..httpClientAdapter = adapter;
    repository = PromocionRepository(dio: dio);
  });

  RequestOptions ultimaPeticion() =>
      verify(() => adapter.fetch(captureAny(), any(), any())).captured.last
          as RequestOptions;

  test('listar lee la franja y los resultados', () async {
    when(
      () => adapter.fetch(any(), any(), any()),
    ).thenAnswer((_) async => jsonResponseBody([horarioJson], 200));

    final promo = (await repository.listar()).single;

    expect(promo.tipo, TipoPromocion.horario);
    expect(promo.franja, 'Mar, Mié · 08:00–11:00');
    expect(promo.descuentoOtorgado, 81000);
    expect(promo.vencida(hoy: DateTime(2027, 1, 1)), isTrue);
    expect(promo.vencida(hoy: DateTime(2026, 12, 31, 23)), isFalse);
  });

  test('crear un cupón envía solo los campos de cupón', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({
        ...horarioJson,
        'tipo': 'CUPON',
        'codigo': 'HOLA10',
        'dias': <String>[],
        'horaDesde': null,
        'horaHasta': null,
      }, 201),
    );

    await repository.crear(
      nombre: ' Bienvenida ',
      tipo: TipoPromocion.cupon,
      tipoDescuento: TipoDescuento.porcentaje,
      valorDescuento: 10,
      vigenteDesde: DateTime(2026, 11, 20),
      vigenteHasta: DateTime(2026, 12, 5),
      codigo: 'hola10',
      dias: [DiaSemana.lunes],
    );

    expect(ultimaPeticion().data, {
      'nombre': 'Bienvenida',
      'tipo': 'CUPON',
      'tipoDescuento': 'PORCENTAJE',
      'valorDescuento': 10,
      'vigenteDesde': '2026-11-20',
      'vigenteHasta': '2026-12-05',
      'codigo': 'hola10',
    });
  });

  test('cotizar envía la hora en UTC y el cupón, y lee el descuento', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({
        'precioLista': 45000,
        'descuento': 9000,
        'precioFinal': 36000,
        'moneda': 'COP',
        'promocionId': 'p-1',
        'promocionNombre': 'Mañanas de martes',
      }, 200),
    );

    final cotizacion = await repository.cotizar(
      servicioId: 's-1',
      fechaHoraInicio: DateTime.utc(2026, 11, 24, 14),
      cupon: '  ',
    );

    expect(ultimaPeticion().queryParameters, {
      'servicioId': 's-1',
      'fechaHoraInicio': '2026-11-24T14:00:00.000Z',
    });
    expect(cotizacion.tieneDescuento, isTrue);
    expect(cotizacion.precioFinal, 36000);
  });

  test('un cupón inválido llega como ApiException con el motivo', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({
        'message': "El cupón 'XYZ' no existe o ya no está activo",
      }, 400),
    );

    expect(
      () => repository.cotizar(
        servicioId: 's-1',
        fechaHoraInicio: DateTime.utc(2026, 11, 24),
        cupon: 'xyz',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('XYZ'),
        ),
      ),
    );
  });
}
