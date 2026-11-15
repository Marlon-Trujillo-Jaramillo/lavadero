import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';

/// Estado de "Mis vehículos".
class VehiclesState {
  const VehiclesState({
    this.vehiculos = const [],
    this.isLoading = false,
    this.archivandoId,
    this.errorMessage,
  });

  final List<Vehiculo> vehiculos;
  final bool isLoading;

  /// Id del vehículo que se está archivando (deshabilita solo esa tarjeta).
  final String? archivandoId;
  final String? errorMessage;

  VehiclesState copyWith({
    List<Vehiculo>? vehiculos,
    bool? isLoading,
    String? archivandoId,
    bool clearArchivandoId = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VehiclesState(
      vehiculos: vehiculos ?? this.vehiculos,
      isLoading: isLoading ?? this.isLoading,
      archivandoId: clearArchivandoId
          ? null
          : (archivandoId ?? this.archivandoId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final vehiclesControllerProvider =
    NotifierProvider<VehiclesController, VehiclesState>(VehiclesController.new);

class VehiclesController extends Notifier<VehiclesState> {
  @override
  VehiclesState build() {
    Future.microtask(cargar);
    return const VehiclesState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final vehiculos = await ref.read(vehiculoRepositoryProvider).misVehiculos();
      state = state.copyWith(vehiculos: vehiculos, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Lanza [ApiException] para que el formulario muestre el error en su lugar
  /// (p. ej. "Ya tienes un vehículo con la placa ABC123").
  Future<Vehiculo> registrar({
    required String placa,
    required TipoVehiculo tipo,
    String? marca,
    String? color,
  }) async {
    final vehiculo = await ref
        .read(vehiculoRepositoryProvider)
        .registrar(placa: placa, tipo: tipo, marca: marca, color: color);
    state = state.copyWith(vehiculos: [vehiculo, ...state.vehiculos]);
    return vehiculo;
  }

  Future<void> archivar(String vehiculoId) async {
    state = state.copyWith(archivandoId: vehiculoId, clearError: true);
    try {
      await ref.read(vehiculoRepositoryProvider).archivar(vehiculoId);
      state = state.copyWith(
        vehiculos: state.vehiculos.where((v) => v.id != vehiculoId).toList(),
        clearArchivandoId: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(clearArchivandoId: true, errorMessage: e.message);
    }
  }
}
