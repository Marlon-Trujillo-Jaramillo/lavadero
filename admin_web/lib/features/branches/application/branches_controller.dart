import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Estado de las sucursales del tenant actual — mismo patrón que
/// `SubscriptionPlanState`.
class BranchesState {
  const BranchesState({
    this.sucursales = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Sucursal> sucursales;
  final bool isLoading;
  final String? errorMessage;

  BranchesState copyWith({
    List<Sucursal>? sucursales,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return BranchesState(
      sucursales: sucursales ?? this.sucursales,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final branchesControllerProvider =
    NotifierProvider<BranchesController, BranchesState>(BranchesController.new);

class BranchesController extends Notifier<BranchesState> {
  @override
  BranchesState build() {
    Future.microtask(cargar);
    return const BranchesState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sucursales = await ref
          .read(schedulingRepositoryProvider)
          .listarSucursales();
      state = state.copyWith(sucursales: sucursales, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Lanza la excepción hacia quien llama (el diálogo del formulario) — mismo patrón que
  /// `SubscriptionPlanController.crear`.
  Future<void> crear({
    required String nombre,
    String? direccion,
    required int capacidadSimultanea,
  }) async {
    await ref
        .read(schedulingRepositoryProvider)
        .crearSucursal(
          nombre: nombre,
          direccion: direccion,
          capacidadSimultanea: capacidadSimultanea,
        );
    await cargar();
  }

  Future<void> actualizar({
    required String id,
    required String nombre,
    String? direccion,
    required int capacidadSimultanea,
  }) async {
    await ref
        .read(schedulingRepositoryProvider)
        .actualizarSucursal(
          id: id,
          nombre: nombre,
          direccion: direccion,
          capacidadSimultanea: capacidadSimultanea,
        );
    await cargar();
  }
}
