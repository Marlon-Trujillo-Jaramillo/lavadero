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
  });

  final List<Sucursal> sucursales;
  final String? sucursalSeleccionadaId;
  final DateTime fecha;
  final List<Reserva> reservas;
  final bool isLoading;
  final String? errorMessage;
  final String? cambiandoEstadoId;

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
  }) {
    return AgendaState(
      sucursales: sucursales ?? this.sucursales,
      sucursalSeleccionadaId: sucursalSeleccionadaId ?? this.sucursalSeleccionadaId,
      fecha: fecha ?? this.fecha,
      reservas: reservas ?? this.reservas,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      cambiandoEstadoId:
          clearCambiandoEstadoId ? null : (cambiandoEstadoId ?? this.cambiandoEstadoId),
    );
  }
}

final agendaControllerProvider = NotifierProvider<AgendaController, AgendaState>(
  AgendaController.new,
);

class AgendaController extends Notifier<AgendaState> {
  @override
  AgendaState build() {
    final hoy = DateTime.now();
    Future.microtask(_cargarSucursalesYAgenda);
    return AgendaState(fecha: DateTime(hoy.year, hoy.month, hoy.day), isLoading: true);
  }

  Future<void> _cargarSucursalesYAgenda() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final sucursales = await ref.read(schedulingRepositoryProvider).listarSucursales();
      final sucursalId = sucursales.isEmpty ? null : sucursales.first.id;
      state = state.copyWith(sucursales: sucursales, sucursalSeleccionadaId: sucursalId);
      if (sucursalId != null) {
        await _cargarAgenda();
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> _cargarAgenda() async {
    final sucursalId = state.sucursalSeleccionadaId;
    if (sucursalId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reservas = await ref
          .read(schedulingRepositoryProvider)
          .agendaDelDia(sucursalId: sucursalId, fecha: state.fecha);
      state = state.copyWith(reservas: reservas, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> seleccionarSucursal(String sucursalId) async {
    state = state.copyWith(sucursalSeleccionadaId: sucursalId);
    await _cargarAgenda();
  }

  Future<void> irADia(DateTime fecha) async {
    state = state.copyWith(fecha: DateTime(fecha.year, fecha.month, fecha.day));
    await _cargarAgenda();
  }

  Future<void> irAHoy() async {
    final hoy = DateTime.now();
    await irADia(DateTime(hoy.year, hoy.month, hoy.day));
  }

  Future<void> recargar() => _cargarAgenda();

  Future<void> iniciar(String reservaId) =>
      _cambiarEstado(reservaId, (repo, id) => repo.iniciar(id));

  Future<void> completar(String reservaId) =>
      _cambiarEstado(reservaId, (repo, id) => repo.completar(id));

  Future<void> cancelar(String reservaId) =>
      _cambiarEstado(reservaId, (repo, id) => repo.cancelar(id));

  Future<void> _cambiarEstado(
    String reservaId,
    Future<Reserva> Function(SchedulingRepository repo, String reservaId) accion,
  ) async {
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
