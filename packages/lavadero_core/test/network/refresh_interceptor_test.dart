import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  late MockHttpClientAdapter retryAdapter;
  late MockHttpClientAdapter refreshAdapter;
  late Dio retryDio;
  late Dio refreshDio;
  late TokenStorage tokenStorage;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() async {
    retryAdapter = MockHttpClientAdapter();
    refreshAdapter = MockHttpClientAdapter();
    retryDio = Dio(BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'))
      ..httpClientAdapter = retryAdapter;
    refreshDio =
        Dio(BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'))
          ..httpClientAdapter = refreshAdapter;
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform({});
    tokenStorage = TokenStorage(storage: const FlutterSecureStorage());
    await tokenStorage.saveTokens(
      accessToken: 'expired-access',
      refreshToken: 'valid-refresh',
    );
  });

  RefreshInterceptor buildInterceptor({void Function()? onSessionExpired}) {
    return RefreshInterceptor(
      retryDio: retryDio,
      refreshDio: refreshDio,
      tokenStorage: tokenStorage,
      onSessionExpired: onSessionExpired,
    );
  }

  test('retries the original request once after a successful refresh',
      () async {
    retryDio.interceptors.add(buildInterceptor());

    var call = 0;
    when(() => retryAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
      call++;
      if (call == 1) {
        return jsonResponseBody(
          errorBody(
            status: 401,
            error: 'Unauthorized',
            message: 'Token expirado.',
            path: '/api/v1/client/profile',
          ),
          401,
        );
      }
      return jsonResponseBody({'ok': true}, 200);
    });
    when(() => refreshAdapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody(
        {
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
          'expiresIn': 900,
        },
        200,
      ),
    );

    final response = await retryDio.get<Map<String, dynamic>>(
      '/client/profile',
    );

    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(await tokenStorage.readAccessToken(), 'new-access');
    verify(() => refreshAdapter.fetch(any(), any(), any())).called(1);
    verify(() => retryAdapter.fetch(any(), any(), any())).called(2);
  });

  test('dedupes concurrent refreshes: only one call to /auth/refresh',
      () async {
    retryDio.interceptors.add(buildInterceptor());

    when(() => retryAdapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
      final options = invocation.positionalArguments[0] as RequestOptions;
      final alreadyRetried = options.extra['lavadero_retried'] == true;
      if (!alreadyRetried) {
        return jsonResponseBody(
          errorBody(
            status: 401,
            error: 'Unauthorized',
            message: 'Token expirado.',
            path: options.path,
          ),
          401,
        );
      }
      return jsonResponseBody({'ok': true}, 200);
    });

    var refreshCalls = 0;
    when(() => refreshAdapter.fetch(any(), any(), any())).thenAnswer((_) async {
      refreshCalls++;
      // Simula latencia de red para forzar solapamiento de los dos 401.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return jsonResponseBody(
        {
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
          'expiresIn': 900,
        },
        200,
      );
    });

    final results = await Future.wait([
      retryDio.get<Map<String, dynamic>>('/client/profile'),
      retryDio.get<Map<String, dynamic>>('/client/vehicles'),
    ]);

    expect(results.every((r) => r.statusCode == 200), isTrue);
    expect(refreshCalls, 1);
  });

  test('clears session and calls onSessionExpired when refresh fails',
      () async {
    var sessionExpiredCalled = false;
    retryDio.interceptors.add(
      buildInterceptor(onSessionExpired: () => sessionExpiredCalled = true),
    );

    when(() => retryAdapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody(
        errorBody(
          status: 401,
          error: 'Unauthorized',
          message: 'Token expirado.',
          path: '/api/v1/client/profile',
        ),
        401,
      ),
    );
    when(() => refreshAdapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody(
        errorBody(
          status: 401,
          error: 'Unauthorized',
          message: 'Refresh token inválido.',
          path: '/api/v1/auth/refresh',
        ),
        401,
      ),
    );

    await expectLater(
      retryDio.get<Map<String, dynamic>>('/client/profile'),
      throwsA(isA<DioException>()),
    );

    expect(sessionExpiredCalled, isTrue);
    expect(await tokenStorage.hasSession(), isFalse);
  });

  test('does not attempt refresh for 401s coming from /auth/login', () async {
    retryDio.interceptors.add(buildInterceptor());

    when(() => retryAdapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody(
        errorBody(
          status: 401,
          error: 'Unauthorized',
          message: 'Credenciales inválidas.',
          path: '/api/v1/auth/login',
        ),
        401,
      ),
    );

    await expectLater(
      retryDio.post<Map<String, dynamic>>('/auth/login'),
      throwsA(isA<DioException>()),
    );
    verifyNever(() => refreshAdapter.fetch(any(), any(), any()));
  });
}
