import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

void main() {
  test('maps a backend error body to ApiException', () {
    final requestOptions = RequestOptions(path: '/api/v1/auth/login');
    final dioException = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 400,
        data: {
          'timestamp': '2026-07-20T10:00:00Z',
          'status': 400,
          'error': 'Bad Request',
          'message': 'El email ya está registrado.',
          'path': '/api/v1/auth/register',
        },
      ),
    );

    final exception = ApiException.fromDioException(dioException);

    expect(exception.statusCode, 400);
    expect(exception.message, 'El email ya está registrado.');
    expect(exception.error, 'Bad Request');
    expect(exception.path, '/api/v1/auth/register');
    expect(exception.isValidationError, isTrue);
  });

  test('maps connection errors (no response) to a network ApiException', () {
    final requestOptions = RequestOptions(path: '/api/v1/tenants');
    final dioException = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.connectionError,
    );

    final exception = ApiException.fromDioException(dioException);

    expect(exception.isNetworkError, isTrue);
    expect(exception.statusCode, isNull);
  });

  test('flags 401 responses as isUnauthorized', () {
    final requestOptions = RequestOptions(path: '/api/v1/client/profile');
    final dioException = DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: requestOptions,
        statusCode: 401,
        data: {
          'timestamp': '2026-07-20T10:00:00Z',
          'status': 401,
          'error': 'Unauthorized',
          'message': 'Token inválido.',
          'path': '/api/v1/client/profile',
        },
      ),
    );

    expect(
      ApiException.fromDioException(dioException).isUnauthorized,
      isTrue,
    );
  });
}
