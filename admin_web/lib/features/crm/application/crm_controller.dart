import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Lista del CRM: filtros (segmento, búsqueda, orden) y páginas acumuladas
/// con "Cargar más". Cambiar un filtro vuelve a la primera página.
class CrmState {
  const CrmState({
    this.clientes = const [],
    this.porSegmento = const {},
    this.total = 0,
    this.pagina = 0,
    this.hayMas = false,
    this.segmento,
    this.busqueda = '',
    this.orden = OrdenClientes.ultimaVisita,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<ClienteCrm> clientes;
  final Map<SegmentoCliente, int> porSegmento;
  final int total;
  final int pagina;
  final bool hayMas;
  final SegmentoCliente? segmento;
  final String busqueda;
  final OrdenClientes orden;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  /// Clientes del lavadero que coinciden con la búsqueda, sin importar el
  /// segmento elegido.
  int get totalSinSegmento => porSegmento.values.fold(0, (a, b) => a + b);

  bool get hayFiltros => segmento != null || busqueda.trim().isNotEmpty;

  CrmState copyWith({
    List<ClienteCrm>? clientes,
    Map<SegmentoCliente, int>? porSegmento,
    int? total,
    int? pagina,
    bool? hayMas,
    SegmentoCliente? segmento,
    bool limpiarSegmento = false,
    String? busqueda,
    OrdenClientes? orden,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CrmState(
      clientes: clientes ?? this.clientes,
      porSegmento: porSegmento ?? this.porSegmento,
      total: total ?? this.total,
      pagina: pagina ?? this.pagina,
      hayMas: hayMas ?? this.hayMas,
      segmento: limpiarSegmento ? null : (segmento ?? this.segmento),
      busqueda: busqueda ?? this.busqueda,
      orden: orden ?? this.orden,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final crmControllerProvider = NotifierProvider<CrmController, CrmState>(
  CrmController.new,
);

class CrmController extends Notifier<CrmState> {
  static const tamanoPagina = 25;

  /// Cada carga lleva un número; si llega la respuesta de una búsqueda vieja
  /// después de una nueva (el usuario sigue escribiendo), se descarta.
  int _consulta = 0;

  @override
  CrmState build() {
    Future.microtask(cargar);
    return const CrmState(isLoading: true);
  }

  Future<void> cargar() async {
    final consulta = ++_consulta;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final pagina = await _pedir(0);
      if (consulta != _consulta) return;
      state = state.copyWith(
        clientes: pagina.clientes,
        porSegmento: pagina.porSegmento,
        total: pagina.total,
        pagina: 0,
        hayMas: pagina.hayMas,
        isLoading: false,
      );
    } on ApiException catch (e) {
      if (consulta != _consulta) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> cargarMas() async {
    if (!state.hayMas || state.isLoadingMore || state.isLoading) return;
    final consulta = _consulta;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final pagina = await _pedir(state.pagina + 1);
      if (consulta != _consulta) return;
      state = state.copyWith(
        clientes: [...state.clientes, ...pagina.clientes],
        total: pagina.total,
        pagina: pagina.pagina,
        hayMas: pagina.hayMas,
        isLoadingMore: false,
      );
    } on ApiException catch (e) {
      if (consulta != _consulta) return;
      state = state.copyWith(isLoadingMore: false, errorMessage: e.message);
    }
  }

  Future<void> elegirSegmento(SegmentoCliente? segmento) {
    state = state.copyWith(
      segmento: segmento,
      limpiarSegmento: segmento == null,
    );
    return cargar();
  }

  Future<void> buscar(String texto) {
    if (texto.trim() == state.busqueda.trim()) return Future.value();
    state = state.copyWith(busqueda: texto);
    return cargar();
  }

  Future<void> ordenar(OrdenClientes orden) {
    state = state.copyWith(orden: orden);
    return cargar();
  }

  Future<PaginaClientes> _pedir(int pagina) {
    return ref
        .read(crmRepositoryProvider)
        .clientes(
          segmento: state.segmento,
          busqueda: state.busqueda,
          orden: state.orden,
          pagina: pagina,
          tamano: tamanoPagina,
        );
  }
}

/// Ficha de un cliente, cargada al abrir su detalle.
final fichaClienteProvider = FutureProvider.autoDispose
    .family<FichaCliente, String>((ref, clienteId) {
      return ref.read(crmRepositoryProvider).ficha(clienteId);
    });
