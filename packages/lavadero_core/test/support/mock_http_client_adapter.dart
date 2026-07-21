import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';

/// Mock del transporte HTTP de Dio (capa más baja: [HttpClientAdapter]).
/// Permite simular respuestas del backend (incluyendo el shape exacto del
/// contrato `/api/v1`) sin necesitar el backend real corriendo.
class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

class FakeRequestOptions extends Fake implements RequestOptions {}

/// Construye un [ResponseBody] JSON como lo haría el backend real.
ResponseBody jsonResponseBody(Object? json, int statusCode) {
  final bytes = utf8.encode(jsonEncode(json));
  return ResponseBody.fromBytes(
    Uint8List.fromList(bytes),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

/// Body de error estándar del backend: `{ timestamp, status, error, message, path }`.
Map<String, dynamic> errorBody({
  required int status,
  required String error,
  required String message,
  required String path,
}) =>
    {
      'timestamp': DateTime.utc(2026, 1, 1).toIso8601String(),
      'status': status,
      'error': error,
      'message': message,
      'path': path,
    };
