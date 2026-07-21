import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Estado del catálogo de servicios — vista de administración (incluye
/// inactivos). Mismo patrón que `TenantSelectionState` (mobile_app).
class CatalogPricingState {
  const CatalogPricingState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<ServiceItem> items;
  final bool isLoading;
  final String? errorMessage;

  CatalogPricingState copyWith({
    List<ServiceItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CatalogPricingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final catalogPricingControllerProvider =
    NotifierProvider<CatalogPricingController, CatalogPricingState>(
  CatalogPricingController.new,
);

class CatalogPricingController extends Notifier<CatalogPricingState> {
  @override
  CatalogPricingState build() {
    Future.microtask(cargar);
    return const CatalogPricingState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await ref.read(catalogRepositoryProvider).listar();
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Lanza la excepción hacia quien llama (el diálogo del formulario, que
  /// muestra su propio loading/error local) — mismo patrón que
  /// `AdminAuthController.login`, que tampoco atrapa `ApiException`.
  Future<void> crear({
    required String nombre,
    String? descripcion,
    required int duracionEstimadaMinutos,
    required double precio,
  }) async {
    await ref.read(catalogRepositoryProvider).crear(
          nombre: nombre,
          descripcion: descripcion,
          duracionEstimadaMinutos: duracionEstimadaMinutos,
          precio: precio,
        );
    await cargar();
  }

  Future<void> actualizar({
    required String id,
    required String nombre,
    String? descripcion,
    required int duracionEstimadaMinutos,
    required double precio,
  }) async {
    await ref.read(catalogRepositoryProvider).actualizar(
          id: id,
          nombre: nombre,
          descripcion: descripcion,
          duracionEstimadaMinutos: duracionEstimadaMinutos,
          precio: precio,
        );
    await cargar();
  }

  Future<void> cambiarEstado({required String id, required bool activo}) async {
    await ref.read(catalogRepositoryProvider).cambiarEstado(id: id, activo: activo);
    await cargar();
  }
}
