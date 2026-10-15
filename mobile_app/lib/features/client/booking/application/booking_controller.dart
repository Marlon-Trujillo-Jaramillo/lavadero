import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';

/// Estado de la pantalla de reserva: catálogo + sucursales para elegir, más el resultado del envío.
class BookingState {
  const BookingState({
    this.servicios = const [],
    this.sucursales = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.reservaCreada,
  });

  final List<ServiceItem> servicios;
  final List<Sucursal> sucursales;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final Reserva? reservaCreada;

  BookingState copyWith({
    List<ServiceItem>? servicios,
    List<Sucursal>? sucursales,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    Reserva? reservaCreada,
  }) {
    return BookingState(
      servicios: servicios ?? this.servicios,
      sucursales: sucursales ?? this.sucursales,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      reservaCreada: reservaCreada ?? this.reservaCreada,
    );
  }
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingState>(BookingController.new);

class BookingController extends Notifier<BookingState> {
  @override
  BookingState build() {
    Future.microtask(cargarOpciones);
    return const BookingState(isLoading: true);
  }

  Future<void> cargarOpciones() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final servicios = await ref
          .read(catalogRepositoryProvider)
          .listarActivos();
      final sucursales = await ref
          .read(schedulingRepositoryProvider)
          .listarSucursales();
      state = state.copyWith(
        servicios: servicios,
        sucursales: sucursales,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> reservar({
    required String sucursalId,
    required String servicioId,
    required DateTime fechaHoraInicio,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final reserva = await ref
          .read(schedulingRepositoryProvider)
          .crear(
            sucursalId: sucursalId,
            servicioId: servicioId,
            fechaHoraInicio: fechaHoraInicio,
          );
      state = state.copyWith(isSubmitting: false, reservaCreada: reserva);
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    }
  }

  /// Vuelve a la pantalla de elegir servicio/horario después de confirmar una reserva.
  void reiniciar() {
    state = BookingState(
      servicios: state.servicios,
      sucursales: state.sucursales,
    );
  }
}

/// Servicio elegido para reservar. Vive fuera de la pantalla porque se puede
/// elegir desde el inicio (tarjeta de servicio) antes de abrir "Reservar".
final servicioElegidoProvider =
    NotifierProvider<ServicioElegidoController, ServiceItem?>(
      ServicioElegidoController.new,
    );

class ServicioElegidoController extends Notifier<ServiceItem?> {
  @override
  ServiceItem? build() => null;

  void elegir(ServiceItem? servicio) => state = servicio;
}
