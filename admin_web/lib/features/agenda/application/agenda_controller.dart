import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Agenda del día de una sucursal del tenant, vista de administración: a diferencia de la agenda
/// de empleado (`mobile_app`, acotada a `user.sucursalId`), un admin puede tener varias sucursales
/// y necesita elegir cuál mirar — de ahí el selector de sucursal además del de fecha.
class AgendaState {
  const AgendaState({
    this.sucursales = const [],
    this.sucursalSeleccionadaId,
    required this.fecha,
    this.reservas = const [],
    this.isLoading = false,
    this.errorMessage,
    this.cambiandoEstadoId,
    this.servicios = const {},
  });

  final List<Sucursal> sucursales;
  final String? sucursalSeleccionadaId;
  final DateTime fecha;
  final List<Reserva> reservas;
  final bool isLoading;
  final String? errorMessage;
  final String? cambiandoEstadoId;

  /// Catálogo del tenant indexado por id, para mostrar el NOMBRE del servicio de cada reserva
  /// (la reserva solo trae `servicioId`). Si no se pudo cargar, la agenda funciona igual.
  final Map<String, ServiceItem> servicios;

  int contar(ReservaEstado estado) =>
      reservas.where((r) => r.estado == estado).length;

  AgendaState copyWith({
    List<Sucursal>? sucursales,
    String? sucursalSeleccionadaId,
    DateTime? fecha,
    List<Reserva>? reservas,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    String? cambiandoEstadoId,
    bool clearCambiandoEstadoId = false,
    Map<String, ServiceItem>? servicios,
  }) {
    return AgendaState(
      sucursales: sucursales ?? this.sucursales,
      sucursalSeleccionadaId:
          sucursalSeleccionadaId ?? this.sucursalSeleccionadaId,
      fecha: fecha ?? this.fecha,
      reservas: reservas ?? this.reservas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cambiandoEstadoId: clearCambiandoEstadoId
          ? null
          : (cambiandoEstadoId ?? this.cambiandoEstadoId),
      servicios: servicios ?? this.servicios,
    );
  }
}

final agendaControllerProvider =
    NotifierProvider<AgendaController, AgendaState>(AgendaController.new);

class AgendaController extends Notifier<AgendaState> {
  /// Se incrementa en cada carga de agenda: si el usuario cambia de día/sucursal antes de que
  /// llegue la respuesta anterior, la respuesta vieja se descarta (antes podía pisar a la nueva y
  /// mostrar las reservas de otro día bajo la fecha elegida).
  int _solicitud = 0;

  @override
  AgendaState build() {
    final hoy = DateTime.now();
    Future.microtask(_cargarSucursalesYAgenda);
    Future.microtask(_cargarServicios);
    return AgendaState(
      fecha: DateTime(hoy.year, hoy.month, hoy.day),
      isLoading: true,
    );
  }

  Future<void> _cargarSucursalesYAgenda() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sucursales = await ref
          .read(schedulingRepositoryProvider)
          .listarSucursales();
      final sucursalId = sucursales.isEmpty ? null : sucursales.first.id;
      state = state.copyWith(
        sucursales: sucursales,
        sucursalSeleccionadaId: sucursalId,
      );
      if (sucursalId != null) {
        await _cargarAgenda();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> _cargarServicios() async {
    try {
      final servicios = await ref.read(catalogRepositoryProvider).listar();
      state = state.copyWith(servicios: {for (final s in servicios) s.id: s});
    } on ApiException {
      // No bloquea la agenda: sin catálogo, la fila muestra "Servicio" genérico.
    }
  }

  Future<void> _cargarAgenda() async {
    final sucursalId = state.sucursalSeleccionadaId;
    if (sucursalId == null) return;
    final solicitud = ++_solicitud;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reservas = await ref
          .read(schedulingRepositoryProvider)
          .agendaDelDia(sucursalId: sucursalId, fecha: state.fecha);
      if (solicitud != _solicitud) return;
      final ordenadas = [...reservas]
        ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));
      state = state.copyWith(reservas: ordenadas, isLoading: false);
    } on ApiException catch (e) {
      if (solicitud != _solicitud) return;
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Al cambiar de sucursal o de día se vacía la lista: antes quedaban visibles las reservas del
  /// contexto anterior mientras cargaba (o para siempre, si la carga fallaba).
  Future<void> seleccionarSucursal(String sucursalId) async {
    if (sucursalId == state.sucursalSeleccionadaId) return;
    state = state.copyWith(
      sucursalSeleccionadaId: sucursalId,
      reservas: const [],
    );
    await _cargarAgenda();
  }

  Future<void> irADia(DateTime fecha) async {
    state = state.copyWith(
      fecha: DateTime(fecha.year, fecha.month, fecha.day),
      reservas: const [],
    );
    await _cargarAgenda();
  }

  Future<void> irAHoy() async {
    final hoy = DateTime.now();
    await irADia(DateTime(hoy.year, hoy.month, hoy.day));
  }

  /// Reintento genérico: si ni siquiera se pudieron cargar las sucursales, vuelve a empezar por
  /// ahí (antes `recargar` no hacía nada en ese caso porque no había sucursal seleccionada).
  Future<void> recargar() => state.sucursalSeleccionadaId == null
      ? _cargarSucursalesYAgenda()
      : _cargarAgenda();

  void descartarError() => state = state.copyWith(clearError: true);

  Future<void> iniciar(String reservaId) =>
      _cambiarEstado(reservaId, (repo, id) => repo.iniciar(id));

  Future<void> completar(String reservaId) =>
      _cambiarEstado(reservaId, (repo, id) => repo.completar(id));

  Future<void> cancelar(String reservaId) =>
      _cambiarEstado(reservaId, (repo, id) => repo.cancelar(id));

  Future<void> _cambiarEstado(
    String reservaId,
    Future<Reserva> Function(SchedulingRepository repo, String reservaId)
    accion,
  ) async {
    // Una acción a la vez: el estado solo sigue un `cambiandoEstadoId`.
    if (state.cambiandoEstadoId != null) return;
    state = state.copyWith(cambiandoEstadoId: reservaId, clearError: true);
    try {
      await accion(ref.read(schedulingRepositoryProvider), reservaId);
      await _cargarAgenda();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } finally {
      state = state.copyWith(clearCambiandoEstadoId: true);
    }
  }
}
