import 'package:dio/dio.dart';

import '../models/cliente_crm.dart';
import '../network/api_exception.dart';

/// CRM de clientes del dueño/admin de sucursal (`/api/v1/crm/clientes`).
class CrmRepository {
  CrmRepository({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<PaginaClientes> clientes({
    SegmentoCliente? segmento,
    String? busqueda,
    OrdenClientes orden = OrdenClientes.ultimaVisita,
    int pagina = 0,
    int tamano = 25,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/crm/clientes',
        queryParameters: {
          if (segmento != null) 'segmento': segmento.wireValue,
          if (busqueda != null && busqueda.trim().isNotEmpty)
            'q': busqueda.trim(),
          'orden': orden.wireValue,
          'pagina': pagina,
          'tamano': tamano,
        },
      );
      return PaginaClientes.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<FichaCliente> ficha(String clienteId) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/crm/clientes/$clienteId',
      );
      return FichaCliente.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
