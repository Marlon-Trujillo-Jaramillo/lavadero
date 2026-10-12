import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Estado del staff (rol EMPLEADO) del tenant actual — mismo patrón que `BranchesState`. Incluye
/// las sucursales del tenant (para el selector "asignar a sucursal" del formulario de alta).
class EmployeesState {
  const EmployeesState({
    this.empleados = const [],
    this.sucursales = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Empleado> empleados;
  final List<Sucursal> sucursales;
  final bool isLoading;
  final String? errorMessage;

  EmployeesState copyWith({
    List<Empleado>? empleados,
    List<Sucursal>? sucursales,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return EmployeesState(
      empleados: empleados ?? this.empleados,
      sucursales: sucursales ?? this.sucursales,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final employeesControllerProvider = NotifierProvider<EmployeesController, EmployeesState>(
  EmployeesController.new,
);

class EmployeesController extends Notifier<EmployeesState> {
  @override
  EmployeesState build() {
    Future.microtask(cargar);
    return const EmployeesState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final empleados = await ref.read(empleadoRepositoryProvider).listar();
      final sucursales = await ref.read(schedulingRepositoryProvider).listarSucursales();
      state = state.copyWith(empleados: empleados, sucursales: sucursales, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Lanza la excepción hacia quien llama (el diálogo del formulario) — mismo patrón que
  /// `BranchesController.crear`.
  Future<void> crear({
    required String email,
    required String password,
    required String nombre,
    String? sucursalId,
  }) async {
    await ref
        .read(empleadoRepositoryProvider)
        .crear(email: email, password: password, nombre: nombre, sucursalId: sucursalId);
    await cargar();
  }
}
