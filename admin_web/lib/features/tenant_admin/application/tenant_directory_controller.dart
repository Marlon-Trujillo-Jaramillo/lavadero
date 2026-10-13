import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Directorio de lavaderos activos de la plataforma (vista SUPER_ADMIN), sobre la misma búsqueda
/// pública `GET /api/v1/tenants?query=` que usa la selección de lavadero de `mobile_app` (con
/// `query` vacío devuelve todos los activos).
class TenantDirectoryState {
  const TenantDirectoryState({
    this.tenants = const [],
    this.query = '',
    this.isLoading = false,
    this.errorMessage,
  });

  final List<TenantSummary> tenants;
  final String query;
  final bool isLoading;
  final String? errorMessage;

  TenantDirectoryState copyWith({
    List<TenantSummary>? tenants,
    String? query,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TenantDirectoryState(
      tenants: tenants ?? this.tenants,
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final tenantDirectoryControllerProvider =
    NotifierProvider<TenantDirectoryController, TenantDirectoryState>(
      TenantDirectoryController.new,
    );

class TenantDirectoryController extends Notifier<TenantDirectoryState> {
  static const _espera = Duration(milliseconds: 300);

  Timer? _debounce;
  int _solicitud = 0;

  @override
  TenantDirectoryState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(cargar);
    return const TenantDirectoryState(isLoading: true);
  }

  /// Búsqueda mientras se escribe, con una pausa corta para no disparar una petición por tecla.
  void buscar(String query) {
    state = state.copyWith(query: query);
    _debounce?.cancel();
    _debounce = Timer(_espera, cargar);
  }

  Future<void> cargar() async {
    final solicitud = ++_solicitud;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final tenants = await ref
          .read(tenantRepositoryProvider)
          .search(state.query.trim());
      if (solicitud != _solicitud) return;
      state = state.copyWith(tenants: tenants, isLoading: false);
    } on ApiException catch (e) {
      if (solicitud != _solicitud) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
