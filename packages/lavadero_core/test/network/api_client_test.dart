import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mocktail/mocktail.dart';

import '../support/mock_http_client_adapter.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(FakeRequestOptions());
  });

  test('appends /api/v1 to the configured baseUrl exactly once', () {
    final client = ApiClient(
      baseUrl: 'https://api.dev.lavadero.app',
      tokenStorage: TokenStorage(storage: const FlutterSecureStorage()),
    );
    expect(client.dio.options.baseUrl, 'https://api.dev.lavadero.app/api/v1');

    final alreadyPrefixed = ApiClient(
      baseUrl: 'https://api.dev.lavadero.app/api/v1',
      tokenStorage: TokenStorage(storage: const FlutterSecureStorage()),
    );
    expect(
      alreadyPrefixed.dio.options.baseUrl,
      'https://api.dev.lavadero.app/api/v1',
    );
  });

  test('adds X-Tenant-Slug and Authorization headers on protected calls',
      () async {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform({});
    final tokenStorage = TokenStorage(storage: const FlutterSecureStorage());
    await tokenStorage.saveTokens(accessToken: 'abc', refreshToken: 'r');

    final adapter = MockHttpClientAdapter();
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody({'ok': true}, 200),
    );

    final client = ApiClient(
      baseUrl: 'https://api.dev.lavadero.app',
      tokenStorage: tokenStorage,
      tenantSlugProvider: () => 'lavadero-central',
    )..dio.httpClientAdapter = adapter;

    await client.dio.get<Map<String, dynamic>>('/client/profile');

    final captured = verify(() => adapter.fetch(captureAny(), any(), any()))
        .captured
        .single as RequestOptions;
    expect(captured.headers['X-Tenant-Slug'], 'lavadero-central');
    expect(captured.headers['Authorization'], 'Bearer abc');
  });

  test('does not add Authorization for public endpoints', () async {
    FlutterSecureStoragePlatform.instance =
        TestFlutterSecureStoragePlatform({});
    final tokenStorage = TokenStorage(storage: const FlutterSecureStorage());
    await tokenStorage.saveTokens(accessToken: 'abc', refreshToken: 'r');

    final adapter = MockHttpClientAdapter();
    when(() => adapter.fetch(any(), any(), any())).thenAnswer(
      (_) async => jsonResponseBody([], 200),
    );

    final client = ApiClient(
      baseUrl: 'https://api.dev.lavadero.app',
      tokenStorage: tokenStorage,
    )..dio.httpClientAdapter = adapter;

    await client.dio.get<List<dynamic>>(
      '/tenants',
      queryParameters: {'query': 'a'},
    );

    final captured = verify(() => adapter.fetch(captureAny(), any(), any()))
        .captured
        .single as RequestOptions;
    expect(captured.headers.containsKey('Authorization'), isFalse);
  });
}
