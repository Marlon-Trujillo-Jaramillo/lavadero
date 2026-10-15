import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';
import '../../../auth/application/auth_controller.dart';

/// Agenda del día de la sucursal del empleado actual (`user.sucursalId`).
class AgendaState {
  const AgendaState({
    this.reservas = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Reserva> reservas;
  final bool isLoading;
  final String? errorMessage;

  AgendaState copyWith({
    List<Reserva>? reservas,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AgendaState(
      reservas: reservas ?? this.reservas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final agendaControllerProvider =
    NotifierProvider<AgendaController, AgendaState>(AgendaController.new);

class AgendaController extends Notifier<AgendaState> {
  @override
  AgendaState build() {
    Future.microtask(cargar);
    return const AgendaState(isLoading: true);
  }

  Future<void> cargar() async {
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated || authState.user.sucursalId == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Tu usuario no tiene una sucursal asignada.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reservas = await ref
          .read(schedulingRepositoryProvider)
          .agendaDelDia(
            sucursalId: authState.user.sucursalId!,
            fecha: DateTime.now(),
          );
      state = state.copyWith(reservas: reservas, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> iniciar(String reservaId) async {
    await ref.read(schedulingRepositoryProvider).iniciar(reservaId);
    await cargar();
  }

  Future<void> completar(String reservaId) async {
    await ref.read(schedulingRepositoryProvider).completar(reservaId);
    await cargar();
  }
}
