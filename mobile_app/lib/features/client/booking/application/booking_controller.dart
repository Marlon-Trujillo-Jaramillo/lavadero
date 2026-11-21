import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';

/// Estado de la pantalla de reserva: catálogo + sucursales para elegir, más el resultado del envío.
class BookingState {
  const BookingState({
    this.servicios = const [],
    this.sucursales = const [],
    this.vehiculos = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.reservaCreada,
    this.cotizacion,
    this.cupon,
    this.cuponError,
    this.isAplicandoCupon = false,
  });

  final List<ServiceItem> servicios;
  final List<Sucursal> sucursales;

  /// Vehículos del cliente para elegir (opcional). Vacío si no tiene o si
  /// no se pudieron cargar: reservar no depende de ellos.
  final List<Vehiculo> vehiculos;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final Reserva? reservaCreada;

  /// Precio con la mejor promoción para el servicio y hora elegidos. `null`
  /// mientras no haya ambos o si no se pudo cotizar: se muestra el de lista.
  final Cotizacion? cotizacion;

  /// Cupón aplicado (ya validado por el backend) y, si el último que se
  /// intentó no sirvió, el motivo.
  final String? cupon;
  final String? cuponError;
  final bool isAplicandoCupon;

  BookingState copyWith({
    List<ServiceItem>? servicios,
    List<Sucursal>? sucursales,
    List<Vehiculo>? vehiculos,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    Reserva? reservaCreada,
    Cotizacion? cotizacion,
    bool limpiarCotizacion = false,
    String? cupon,
    bool limpiarCupon = false,
    String? cuponError,
    bool limpiarCuponError = false,
    bool? isAplicandoCupon,
  }) {
    return BookingState(
      servicios: servicios ?? this.servicios,
      sucursales: sucursales ?? this.sucursales,
      vehiculos: vehiculos ?? this.vehiculos,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      reservaCreada: reservaCreada ?? this.reservaCreada,
      cotizacion: limpiarCotizacion ? null : (cotizacion ?? this.cotizacion),
      cupon: limpiarCupon ? null : (cupon ?? this.cupon),
      cuponError: limpiarCuponError ? null : (cuponError ?? this.cuponError),
      isAplicandoCupon: isAplicandoCupon ?? this.isAplicandoCupon,
    );
  }
}

final bookingControllerProvider =
    NotifierProvider<BookingController, BookingState>(BookingController.new);

class BookingController extends Notifier<BookingState> {
  /// Cada cotización lleva un número: si el cliente cambia de hora antes de
  /// que llegue la respuesta anterior, esa respuesta se descarta.
  int _cotizacion = 0;

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
        vehiculos: await _vehiculosSinFallar(),
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
    String? vehiculoId,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final reserva = await ref
          .read(schedulingRepositoryProvider)
          .crear(
            sucursalId: sucursalId,
            servicioId: servicioId,
            fechaHoraInicio: fechaHoraInicio,
            vehiculoId: vehiculoId,
            codigoCupon: state.cupon,
          );
      state = state.copyWith(isSubmitting: false, reservaCreada: reserva);
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, errorMessage: e.message);
    }
  }

  /// Cotiza el precio del servicio a esa hora con el cupón aplicado (si hay).
  /// Sin servicio u hora, limpia la cotización. Si falla, se queda el precio
  /// de lista: reservar no depende de esto.
  Future<void> cotizar({String? servicioId, DateTime? fechaHoraInicio}) async {
    final consulta = ++_cotizacion;
    if (servicioId == null || fechaHoraInicio == null) {
      state = state.copyWith(limpiarCotizacion: true);
      return;
    }
    try {
      final cotizacion = await ref
          .read(promocionRepositoryProvider)
          .cotizar(
            servicioId: servicioId,
            fechaHoraInicio: fechaHoraInicio,
            cupon: state.cupon,
          );
      if (consulta != _cotizacion) return;
      state = state.copyWith(cotizacion: cotizacion);
    } on ApiException catch (e) {
      if (consulta != _cotizacion) return;
      if (state.cupon != null) {
        // El cupón dejó de servir para esta hora (p. ej. vence antes de ese
        // día): se quita, se explica y se cotiza sin él.
        state = state.copyWith(limpiarCupon: true, cuponError: e.message);
        await cotizar(servicioId: servicioId, fechaHoraInicio: fechaHoraInicio);
        return;
      }
      state = state.copyWith(limpiarCotizacion: true);
    }
  }

  /// Valida el cupón cotizando con él. Si no sirve, queda el motivo en
  /// [BookingState.cuponError] y no se aplica.
  Future<void> aplicarCupon({
    required String codigo,
    required String servicioId,
    required DateTime fechaHoraInicio,
  }) async {
    final consulta = ++_cotizacion;
    state = state.copyWith(isAplicandoCupon: true, limpiarCuponError: true);
    try {
      final cotizacion = await ref
          .read(promocionRepositoryProvider)
          .cotizar(
            servicioId: servicioId,
            fechaHoraInicio: fechaHoraInicio,
            cupon: codigo,
          );
      if (consulta != _cotizacion) return;
      state = state.copyWith(
        cupon: codigo.trim().toUpperCase(),
        cotizacion: cotizacion,
        isAplicandoCupon: false,
      );
    } on ApiException catch (e) {
      if (consulta != _cotizacion) return;
      state = state.copyWith(isAplicandoCupon: false, cuponError: e.message);
    }
  }

  Future<void> quitarCupon({String? servicioId, DateTime? fechaHoraInicio}) {
    state = state.copyWith(limpiarCupon: true, limpiarCuponError: true);
    return cotizar(servicioId: servicioId, fechaHoraInicio: fechaHoraInicio);
  }

  /// Vuelve a la pantalla de elegir servicio/horario después de confirmar una reserva.
  void reiniciar() {
    state = BookingState(
      servicios: state.servicios,
      sucursales: state.sucursales,
      vehiculos: state.vehiculos,
    );
  }

  /// Agrega el vehículo recién creado desde la pantalla de reservar.
  void agregarVehiculo(Vehiculo vehiculo) {
    state = state.copyWith(vehiculos: [vehiculo, ...state.vehiculos]);
  }

  Future<List<Vehiculo>> _vehiculosSinFallar() async {
    try {
      return await ref.read(vehiculoRepositoryProvider).misVehiculos();
    } on ApiException {
      return const [];
    }
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
