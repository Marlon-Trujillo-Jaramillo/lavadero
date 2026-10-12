import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';

/// Estado de la pantalla "Mis reservas".
class MyReservationsState {
  const MyReservationsState({
    this.reservas = const [],
    this.servicios = const {},
    this.isLoading = false,
    this.cancelandoId,
    this.errorMessage,
  });

  final List<Reserva> reservas;

  /// Nombre de servicio por id, para no depender de que el backend embeba
  /// el nombre en `ReservaResponse` (hoy solo trae `servicioId`).
  final Map<String, ServiceItem> servicios;
  final bool isLoading;

  /// Id de la reserva que se está cancelando (para deshabilitar solo ese botón).
  final String? cancelandoId;
  final String? errorMessage;

  MyReservationsState copyWith({
    List<Reserva>? reservas,
    Map<String, ServiceItem>? servicios,
    bool? isLoading,
    String? cancelandoId,
    bool clearCancelandoId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MyReservationsState(
      reservas: reservas ?? this.reservas,
      servicios: servicios ?? this.servicios,
      isLoading: isLoading ?? this.isLoading,
      cancelandoId: clearCancelandoId ? null : (cancelandoId ?? this.cancelandoId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final myReservationsControllerProvider =
    NotifierProvider<MyReservationsController, MyReservationsState>(
  MyReservationsController.new,
);

class MyReservationsController extends Notifier<MyReservationsState> {
  @override
  MyReservationsState build() {
    Future.microtask(cargar);
    return const MyReservationsState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reservas = await ref.read(schedulingRepositoryProvider).misReservas();
      // `listar()` (no `listarActivos()`) para poder mostrar el nombre de
      // servicios ya desactivados en reservas pasadas.
      final servicios = await ref.read(catalogRepositoryProvider).listar();
      // Más recientes primero.
      final ordenadas = [...reservas]
        ..sort((a, b) => b.fechaHoraInicio.compareTo(a.fechaHoraInicio));
      state = state.copyWith(
        reservas: ordenadas,
        servicios: {for (final s in servicios) s.id: s},
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> cancelar(String reservaId) async {
    state = state.copyWith(cancelandoId: reservaId, clearError: true);
    try {
      await ref.read(schedulingRepositoryProvider).cancelar(reservaId);
      await cargar();
    } on ApiException catch (e) {
      state = state.copyWith(clearCancelandoId: true, errorMessage: e.message);
    }
  }
}
