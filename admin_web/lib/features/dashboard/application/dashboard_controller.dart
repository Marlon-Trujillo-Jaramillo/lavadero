import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Resumen de ventas de **hoy** — KPIs rápidos al abrir la app (sin selector de rango, ver
/// `reports` para eso).
class DashboardState {
  const DashboardState({
    this.resumen,
    this.isLoading = false,
    this.errorMessage,
  });

  final ResumenVentas? resumen;
  final bool isLoading;
  final String? errorMessage;

  DashboardState copyWith({
    ResumenVentas? resumen,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      resumen: resumen ?? this.resumen,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardState> {
  @override
  DashboardState build() {
    Future.microtask(cargar);
    return const DashboardState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final hoy = DateTime.now();
      final resumen = await ref
          .read(schedulingRepositoryProvider)
          .resumenVentas(desde: hoy, hasta: hoy);
      state = state.copyWith(resumen: resumen, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
