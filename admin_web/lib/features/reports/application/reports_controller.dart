import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Resumen de ventas + finanzas (utilidad) + gastos para un rango de fechas elegido por el admin
/// (por defecto, los últimos 7 días) — a diferencia de `dashboard`, que siempre es "hoy".
class ReportsState {
  ReportsState({
    this.resumen,
    this.finanzas,
    this.gastos = const [],
    this.isLoading = false,
    this.errorMessage,
    DateTime? desde,
    DateTime? hasta,
  }) : hasta = hasta ?? DateTime.now(),
       desde = desde ?? DateTime.now().subtract(const Duration(days: 6));

  final ResumenVentas? resumen;
  final ResumenFinanciero? finanzas;
  final List<Gasto> gastos;
  final bool isLoading;
  final String? errorMessage;
  final DateTime desde;
  final DateTime hasta;

  ReportsState copyWith({
    ResumenVentas? resumen,
    ResumenFinanciero? finanzas,
    List<Gasto>? gastos,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    DateTime? desde,
    DateTime? hasta,
  }) {
    return ReportsState(
      resumen: resumen ?? this.resumen,
      finanzas: finanzas ?? this.finanzas,
      gastos: gastos ?? this.gastos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
    );
  }
}

final reportsControllerProvider =
    NotifierProvider<ReportsController, ReportsState>(ReportsController.new);

class ReportsController extends Notifier<ReportsState> {
  @override
  ReportsState build() {
    Future.microtask(cargar);
    return ReportsState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    final repo = ref.read(schedulingRepositoryProvider);
    try {
      final (resumen, finanzas, gastos) = await (
        repo.resumenVentas(desde: state.desde, hasta: state.hasta),
        repo.resumenFinanciero(desde: state.desde, hasta: state.hasta),
        repo.listarGastos(desde: state.desde, hasta: state.hasta),
      ).wait;
      state = state.copyWith(
        resumen: resumen,
        finanzas: finanzas,
        gastos: gastos,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> cambiarRango({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    state = state.copyWith(desde: desde, hasta: hasta);
    await cargar();
  }

  /// Registra un gasto y recarga el periodo. Devuelve el mensaje de error, o `null` si salió bien.
  Future<String?> registrarGasto({
    required DateTime fecha,
    required CategoriaGasto categoria,
    required String descripcion,
    required double monto,
  }) async {
    try {
      await ref
          .read(schedulingRepositoryProvider)
          .registrarGasto(
            fecha: fecha,
            categoria: categoria,
            descripcion: descripcion,
            monto: monto,
          );
      await cargar();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }
}
