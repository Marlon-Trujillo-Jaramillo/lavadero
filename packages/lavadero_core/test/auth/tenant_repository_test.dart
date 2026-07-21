import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late Dio dio;
  late TenantRepository tenantRepository;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'))
      ..httpClientAdapter = adapter;
    tenantRepository = TenantRepository(dio: dio);
  });

  test('search parses the tenant list from the backend', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody(
        [
          {
            'id': '11111111-1111-1111-1111-111111111111',
            'slug': 'lavadero-central',
            'nombre': 'Lavadero Central',
          },
          {
            'id': '22222222-2222-2222-2222-222222222222',
            'slug': 'lavadero-norte',
            'nombre': 'Lavadero Norte',
          },
        ],
        200,
      ),
    );

    final results = await tenantRepository.search('lavadero');

    expect(results, hasLength(2));
    expect(results.first.slug, 'lavadero-central');

    final captured = verify(() => adapter.fetch(captureAny(), any(), any()))
        .captured
        .single as RequestOptions;
    expect(captured.path, '/tenants');
    expect(captured.queryParameters['query'], 'lavadero');
  });

  test('maps errors to ApiException', () async {
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody(
        errorBody(
          status: 500,
          error: 'Internal Server Error',
          message: 'Error inesperado.',
          path: '/api/v1/tenants',
        ),
        500,
      ),
    );

    await expectLater(
      tenantRepository.search('x'),
      throwsA(isA<ApiException>().having(
        (e) => e.isServerError,
        'isServerError',
        isTrue,
      )),
    );
  });
}
