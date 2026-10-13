import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Estado de búsqueda de tenants (pantalla pública `tenant_selection`).
class TenantSelectionState {
  const TenantSelectionState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final String query;
  final List<TenantSummary> results;
  final bool isLoading;
  final String? errorMessage;

  TenantSelectionState copyWith({
    String? query,
    List<TenantSummary>? results,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TenantSelectionState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final tenantSelectionControllerProvider =
    NotifierProvider<TenantSelectionController, TenantSelectionState>(
      TenantSelectionController.new,
    );

class TenantSelectionController extends Notifier<TenantSelectionState> {
  @override
  TenantSelectionState build() => const TenantSelectionState();

  Future<void> search(String query) async {
    state = state.copyWith(query: query, isLoading: true, clearError: true);
    if (query.trim().isEmpty) {
      state = state.copyWith(results: [], isLoading: false);
      return;
    }
    try {
      final results = await ref
          .read(tenantRepositoryProvider)
          .search(query.trim());
      // Respuesta de una búsqueda ya superada (el usuario siguió tecleando):
      // se descarta para que no pise los resultados de la consulta actual.
      if (state.query != query) return;
      state = state.copyWith(results: results, isLoading: false);
    } on ApiException catch (e) {
      if (state.query != query) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Al elegir un tenant, se guarda su slug para que `X-Tenant-Slug` viaje
  /// en la siguiente llamada de login/registro.
  void select(TenantSummary tenant) {
    ref.read(selectedTenantSlugProvider.notifier).state = tenant.slug;
    ref.read(selectedTenantNameProvider.notifier).state = tenant.nombre;
  }
}
