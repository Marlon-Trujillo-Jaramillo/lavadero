import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';

/// Estado del catálogo — vista de cliente: solo servicios activos. Mismo
/// patrón que `TenantSelectionState`.
class CatalogState {
  const CatalogState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ServiceItem> items;
  final bool isLoading;
  final String? errorMessage;

  CatalogState copyWith({
    List<ServiceItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CatalogState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final catalogControllerProvider =
    NotifierProvider<CatalogController, CatalogState>(CatalogController.new);

class CatalogController extends Notifier<CatalogState> {
  @override
  CatalogState build() {
    Future.microtask(cargar);
    return const CatalogState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ref.read(catalogRepositoryProvider).listarActivos();
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
