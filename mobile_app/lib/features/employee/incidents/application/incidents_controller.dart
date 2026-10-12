import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';

/// Incidencias reportadas por el empleado actual — ver docs/specs/006-checklist-incidencias.md.
class IncidentsState {
  const IncidentsState({this.incidencias = const [], this.isLoading = false, this.errorMessage});

  final List<Incidencia> incidencias;
  final bool isLoading;
  final String? errorMessage;

  IncidentsState copyWith({
    List<Incidencia>? incidencias,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return IncidentsState(
      incidencias: incidencias ?? this.incidencias,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final incidentsControllerProvider = NotifierProvider<IncidentsController, IncidentsState>(
  IncidentsController.new,
);

class IncidentsController extends Notifier<IncidentsState> {
  @override
  IncidentsState build() {
    Future.microtask(cargar);
    return const IncidentsState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final incidencias = await ref.read(schedulingRepositoryProvider).misIncidencias();
      state = state.copyWith(incidencias: incidencias, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Lanza la excepción hacia quien llama (el diálogo del formulario) — mismo patrón que
  /// `BranchesController.crear`.
  Future<void> crear({
    required String sucursalId,
    String? reservaId,
    required IncidenciaCategoria categoria,
    required String descripcion,
  }) async {
    await ref.read(schedulingRepositoryProvider).crearIncidencia(
          sucursalId: sucursalId,
          reservaId: reservaId,
          categoria: categoria,
          descripcion: descripcion,
        );
    await cargar();
  }
}
