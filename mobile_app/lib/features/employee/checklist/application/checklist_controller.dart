import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';

/// Checklist de servicio de la reserva actualmente seleccionada (ver
/// docs/specs/006-checklist-incidencias.md). Sin `.family`: este proyecto no usa providers
/// parametrizados en ningún otro lado — un solo controller con `seleccionarReserva` cubre el caso
/// de uso real (una reserva a la vez, elegida desde la lista de `ShiftsScreen`).
class ChecklistState {
  const ChecklistState({
    this.reservaId,
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final String? reservaId;
  final List<ChecklistItem> items;
  final bool isLoading;
  final String? errorMessage;

  ChecklistState copyWith({
    List<ChecklistItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChecklistState(
      reservaId: reservaId,
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final checklistControllerProvider =
    NotifierProvider<ChecklistController, ChecklistState>(
      ChecklistController.new,
    );

class ChecklistController extends Notifier<ChecklistState> {
  @override
  ChecklistState build() => const ChecklistState();

  Future<void> seleccionarReserva(String reservaId) async {
    state = ChecklistState(reservaId: reservaId, isLoading: true);
    try {
      final items = await ref
          .read(schedulingRepositoryProvider)
          .obtenerChecklist(reservaId);
      state = state.copyWith(items: items, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> marcar(String tipo, bool completado) async {
    final reservaId = state.reservaId;
    if (reservaId == null) return;
    try {
      final items = await ref
          .read(schedulingRepositoryProvider)
          .marcarChecklistItem(
            reservaId: reservaId,
            tipo: tipo,
            completado: completado,
          );
      state = state.copyWith(items: items, clearError: true);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }
}
