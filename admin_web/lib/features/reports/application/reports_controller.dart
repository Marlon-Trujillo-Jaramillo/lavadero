import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Resumen de ventas para un rango de fechas elegido por el admin (por defecto, los últimos 7
/// días) — a diferencia de `dashboard`, que siempre es "hoy".
class ReportsState {
  ReportsState({
    this.resumen,
    this.isLoading = false,
    this.errorMessage,
    DateTime? desde,
    DateTime? hasta,
  })  : hasta = hasta ?? DateTime.now(),
        desde = desde ?? DateTime.now().subtract(const Duration(days: 6));

  final ResumenVentas? resumen;
  final bool isLoading;
  final String? errorMessage;
  final DateTime desde;
  final DateTime hasta;

  ReportsState copyWith({
    ResumenVentas? resumen,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DateTime? desde,
    DateTime? hasta,
  }) {
    return ReportsState(
      resumen: resumen ?? this.resumen,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
    );
  }
}

final reportsControllerProvider = NotifierProvider<ReportsController, ReportsState>(
  ReportsController.new,
);

class ReportsController extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    Future.microtask(cargar);
    return ReportsState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final resumen = await ref
          .read(schedulingRepositoryProvider)
          .resumenVentas(desde: state.desde, hasta: state.hasta);
      state = state.copyWith(resumen: resumen, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> cambiarRango({required DateTime desde, required DateTime hasta}) async {
    state = state.copyWith(desde: desde, hasta: hasta);
    await cargar();
  }
}
