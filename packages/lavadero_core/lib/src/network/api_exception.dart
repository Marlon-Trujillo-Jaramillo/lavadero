import 'package:dio/dio.dart';

/// Excepción tipada única para todos los errores de red/API del backend.
///
/// El backend responde a cualquier error HTTP con el shape:
/// `{ "timestamp", "status", "error", "message", "path" }`. Esta clase mapea
/// ese body (cuando existe) y también los errores de transporte de Dio
/// (timeouts, sin conexión, cancelaciones) a un único tipo que las apps
/// pueden capturar con un solo `catch (ApiException e)`.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.error,
    this.path,
    this.timestamp,
    this.isNetworkError = false,
  });

  /// Error de transporte: sin conexión, timeout, host no resoluble, etc.
  factory ApiException.network([String? message]) => ApiException(
        message: message ?? 'No fue posible conectar con el servidor. '
            'Verifica tu conexión e intenta de nuevo.',
        isNetworkError: true,
      );

  /// Construye la excepción a partir de un [DioException], intentando leer
  /// el body de error estándar del backend cuando está presente.
  factory ApiException.fromDioException(DioException dioException) {
    final response = dioException.response;
    if (response == null) {
      switch (dioException.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return ApiException.network();
        case DioExceptionType.cancel:
          return const ApiException(
            message: 'La solicitud fue cancelada.',
            isNetworkError: true,
          );
        default:
          return ApiException.network(dioException.message);
      }
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        message: (data['message'] as String?) ??
            'Ocurrió un error inesperado (${response.statusCode}).',
        statusCode: response.statusCode,
        error: data['error'] as String?,
        path: data['path'] as String?,
        timestamp: data['timestamp'] != null
            ? DateTime.tryParse(data['timestamp'].toString())
            : null,
      );
    }

    return ApiException(
      message: 'Ocurrió un error inesperado (${response.statusCode}).',
      statusCode: response.statusCode,
    );
  }

  final String message;
  final int? statusCode;
  final String? error;
  final String? path;
  final DateTime? timestamp;
  final bool isNetworkError;

  bool get isUnauthorized => statusCode == 401;

  bool get isForbidden => statusCode == 403;

  bool get isNotFound => statusCode == 404;

  bool get isValidationError => statusCode == 400 || statusCode == 422;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() => 'ApiException($statusCode, $message)';
}
