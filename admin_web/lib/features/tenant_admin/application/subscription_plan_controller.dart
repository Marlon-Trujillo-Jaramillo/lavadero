import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Estado del catálogo de planes de suscripción de la plataforma — mismo
/// patrón que `CatalogPricingState`.
class SubscriptionPlanState {
  const SubscriptionPlanState({
    this.planes = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<SubscriptionPlan> planes;
  final bool isLoading;
  final String? errorMessage;

  SubscriptionPlanState copyWith({
    List<SubscriptionPlan>? planes,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SubscriptionPlanState(
      planes: planes ?? this.planes,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final subscriptionPlanControllerProvider =
    NotifierProvider<SubscriptionPlanController, SubscriptionPlanState>(
  SubscriptionPlanController.new,
);

class SubscriptionPlanController extends Notifier<SubscriptionPlanState> {
  @override
  SubscriptionPlanState build() {
    Future.microtask(cargar);
    return const SubscriptionPlanState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final planes = await ref.read(tenantRepositoryProvider).listarPlanes();
      state = state.copyWith(planes: planes, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Lanza la excepción hacia quien llama (el diálogo del formulario) —
  /// mismo patrón que `CatalogPricingController.crear`.
  Future<void> crear({
    required String nombre,
    required double precio,
    required int maxSucursales,
    required int maxEmpleados,
    required List<String> features,
  }) async {
    await ref.read(tenantRepositoryProvider).crearPlan(
          nombre: nombre,
          precio: precio,
          maxSucursales: maxSucursales,
          maxEmpleados: maxEmpleados,
          features: features,
        );
    await cargar();
  }

  Future<void> actualizar({
    required String id,
    required String nombre,
    required double precio,
    required int maxSucursales,
    required int maxEmpleados,
    required List<String> features,
  }) async {
    await ref.read(tenantRepositoryProvider).actualizarPlan(
          id: id,
          nombre: nombre,
          precio: precio,
          maxSucursales: maxSucursales,
          maxEmpleados: maxEmpleados,
          features: features,
        );
    await cargar();
  }
}
