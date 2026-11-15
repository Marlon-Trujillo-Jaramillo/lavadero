import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  late MockHttpClientAdapter adapter;
  late Dio dio;
  late TokenStorage tokenStorage;
  late AuthRepository authRepository;

  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  setUp(() {
    adapter = MockHttpClientAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test.lavadero.app/api/v1'))
      ..httpClientAdapter = adapter;
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform({});
    tokenStorage = TokenStorage(storage: const FlutterSecureStorage());
    authRepository = AuthRepository(dio: dio, tokenStorage: tokenStorage);
  });

  final loginResponseJson = {
    'accessToken': 'jwt-access',
    'refreshToken': 'refresh-token-1',
    'expiresIn': 900,
    'user': {
      'id': '11111111-1111-1111-1111-111111111111',
      'email': 'cliente@example.com',
      'roles': ['CLIENTE'],
      'tenantId': '22222222-2222-2222-2222-222222222222',
      'sucursalId': null,
    },
  };

  group('login', () {
    test('stores tokens and returns AuthResponse on 200', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody(loginResponseJson, 200),
      );

      final auth = await authRepository.login(
        tenantSlug: 'lavadero-central',
        email: 'cliente@example.com',
        password: 'secret123',
      );

      expect(auth.accessToken, 'jwt-access');
      expect(auth.user.roles, [UserRole.cliente]);
      expect(await tokenStorage.readAccessToken(), 'jwt-access');
      expect(await tokenStorage.readRefreshToken(), 'refresh-token-1');

      final captured = verify(() => adapter.fetch(captureAny(), any(), any()))
          .captured
          .single as RequestOptions;
      expect(captured.path, '/auth/login');
      expect(captured.headers['X-Tenant-Slug'], 'lavadero-central');
    });

    test('throws ApiException with backend message on 401', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
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
        authRepository.login(
          tenantSlug: 'lavadero-central',
          email: 'cliente@example.com',
          password: 'wrong',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.message, 'message', 'Credenciales inválidas.')
              .having((e) => e.isUnauthorized, 'isUnauthorized', isTrue),
        ),
      );
      expect(await tokenStorage.readAccessToken(), isNull);
    });
  });

  group('register', () {
    test('auto-login: stores tokens on success', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody(loginResponseJson, 200),
      );

      final auth = await authRepository.register(
        tenantSlug: 'lavadero-central',
        email: 'nuevo@example.com',
        password: 'secret123',
        nombre: 'Nuevo Cliente',
      );

      expect(auth.user.email, 'cliente@example.com');
      expect(await tokenStorage.hasSession(), isTrue);

      final captured = verify(() => adapter.fetch(captureAny(), any(), any()))
          .captured
          .single as RequestOptions;
      expect(captured.path, '/auth/register');
    });
  });

  group('registrarLavadero', () {
    test('crea el lavadero sin X-Tenant-Slug y deja la sesión iniciada',
        () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody(loginResponseJson, 200),
      );

      await authRepository.registrarLavadero(
        tenantNombre: 'Lavadero Centro',
        tenantNit: '900123456-7',
        tenantSlug: 'lavadero-centro',
        adminNombre: 'Dueña',
        email: 'duena@lavadero.com',
        password: 'clave-segura',
      );

      expect(await tokenStorage.hasSession(), isTrue);
      final captured = verify(() => adapter.fetch(captureAny(), any(), any()))
          .captured
          .single as RequestOptions;
      expect(captured.path, '/onboarding/tenants');
      expect(captured.headers.containsKey('X-Tenant-Slug'), isFalse);
      expect(captured.data, {
        'tenantNombre': 'Lavadero Centro',
        'tenantNit': '900123456-7',
        'tenantSlug': 'lavadero-centro',
        'adminNombre': 'Dueña',
        'adminEmail': 'duena@lavadero.com',
        'adminPassword': 'clave-segura',
      });
    });

    test('un slug ocupado llega como ApiException y no guarda sesión',
        () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody(
          errorBody(
            status: 400,
            error: 'Bad Request',
            message: "Ya existe un tenant con el slug 'lavadero-centro'",
            path: '/api/v1/onboarding/tenants',
          ),
          400,
        ),
      );

      await expectLater(
        authRepository.registrarLavadero(
          tenantNombre: 'Lavadero Centro',
          tenantNit: '900123456-7',
          tenantSlug: 'lavadero-centro',
          adminNombre: 'Dueña',
          email: 'duena@lavadero.com',
          password: 'clave-segura',
        ),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
      expect(await tokenStorage.hasSession(), isFalse);
    });
  });

  group('refresh', () {
    test('proactive refresh stores new tokens', () async {
      await tokenStorage.saveTokens(
        accessToken: 'old-access',
        refreshToken: 'old-refresh',
      );
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody(
          {
            'accessToken': 'new-access',
            'refreshToken': 'new-refresh',
            'expiresIn': 900,
          },
          200,
        ),
      );

      final tokens = await authRepository.refresh();

      expect(tokens.accessToken, 'new-access');
      expect(await tokenStorage.readAccessToken(), 'new-access');
      expect(await tokenStorage.readRefreshToken(), 'new-refresh');
    });

    test('clears session and throws when refresh token is rejected',
        () async {
      await tokenStorage.saveTokens(
        accessToken: 'old-access',
        refreshToken: 'expired-refresh',
      );
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody(
          errorBody(
            status: 401,
            error: 'Unauthorized',
            message: 'Refresh token inválido o expirado.',
            path: '/api/v1/auth/refresh',
          ),
          401,
        ),
      );

      await expectLater(
        authRepository.refresh(),
        throwsA(isA<ApiException>()),
      );
      expect(await tokenStorage.readAccessToken(), isNull);
      expect(await tokenStorage.readRefreshToken(), isNull);
    });

    test('throws without calling backend when there is no stored session',
        () async {
      await expectLater(
        authRepository.refresh(),
        throwsA(isA<ApiException>()),
      );
      verifyNever(() => adapter.fetch(any(), any(), any()));
    });
  });

  group('restoreSession', () {
    test('returns null when there is no stored session', () async {
      expect(await authRepository.restoreSession(), isNull);
    });

    test('returns the cached user profile after a login', () async {
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => jsonResponseBody(loginResponseJson, 200),
      );
      await authRepository.login(
        tenantSlug: 'lavadero-central',
        email: 'cliente@example.com',
        password: 'secret123',
      );

      final restored = await authRepository.restoreSession();

      expect(restored, isNotNull);
      expect(restored!.email, 'cliente@example.com');
      expect(restored.isCliente, isTrue);
    });
  });

  group('logout', () {
    test('clears local tokens on success (204)', () async {
      await tokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');
      when(() => adapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString('', 204),
      );

      await authRepository.logout();

      expect(await tokenStorage.hasSession(), isFalse);
    });

    test('clears local tokens even if the remote call fails', () async {
      await tokenStorage.saveTokens(accessToken: 'a', refreshToken: 'r');
      when(() => adapter.fetch(any(), any(), any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/auth/logout'),
          type: DioExceptionType.connectionError,
        ),
      );

      await authRepository.logout();

      expect(await tokenStorage.hasSession(), isFalse);
    });
  });
}
