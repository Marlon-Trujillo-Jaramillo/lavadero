import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../../auth/application/admin_auth_controller.dart';

class InventoryState {
  const InventoryState({
    this.sucursales = const [],
    this.sucursalId,
    this.insumos = const [],
    this.costos = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<Sucursal> sucursales;
  final String? sucursalId;
  final List<InsumoStock> insumos;
  final List<CostoServicio> costos;
  final bool isLoading;
  final String? errorMessage;

  int get porReponer => insumos.where((i) => i.bajoMinimo).length;

  InventoryState copyWith({
    List<Sucursal>? sucursales,
    String? sucursalId,
    List<InsumoStock>? insumos,
    List<CostoServicio>? costos,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return InventoryState(
      sucursales: sucursales ?? this.sucursales,
      sucursalId: sucursalId ?? this.sucursalId,
      insumos: insumos ?? this.insumos,
      costos: costos ?? this.costos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Crear insumos y editar recetas es del dueño (ADMIN_TENANT). Entradas,
/// conteos y mínimos también los hace el admin de sucursal.
final puedeGestionarInventarioProvider = Provider<bool>((ref) {
  final auth = ref.watch(adminAuthControllerProvider);
  return auth is AdminAuthAuthenticated &&
      auth.user.hasRole(UserRole.adminTenant);
});

final inventoryControllerProvider =
    NotifierProvider<InventoryController, InventoryState>(
      InventoryController.new,
    );

class InventoryController extends Notifier<InventoryState> {
  InventarioRepository get _repo => ref.read(inventarioRepositoryProvider);

  @override
  InventoryState build() {
    Future.microtask(cargar);
    return const InventoryState(isLoading: true);
  }

  /// Carga sucursales (la primera vez), el stock de la sucursal elegida y
  /// los costos por servicio.
  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      var sucursales = state.sucursales;
      if (sucursales.isEmpty) {
        sucursales = await ref
            .read(schedulingRepositoryProvider)
            .listarSucursales();
      }
      final sucursalId = state.sucursalId ?? sucursales.firstOrNull?.id;
      if (sucursalId == null) {
        state = state.copyWith(sucursales: sucursales, isLoading: false);
        return;
      }
      final insumos = await _repo.insumos(sucursalId: sucursalId);
      final costos = await _repo.costos();
      state = state.copyWith(
        sucursales: sucursales,
        sucursalId: sucursalId,
        insumos: insumos,
        costos: costos,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  Future<void> elegirSucursal(String sucursalId) {
    state = state.copyWith(sucursalId: sucursalId);
    return cargar();
  }

  // Las operaciones de abajo lanzan ApiException para que el diálogo que las
  // llamó muestre el motivo; si salen bien, se recarga la vista.

  Future<void> crearInsumo({
    required String nombre,
    required UnidadMedida unidad,
    required num costoUnitario,
    num? stockInicial,
    num? minimo,
  }) async {
    final id = await _repo.crearInsumo(
      nombre: nombre,
      unidad: unidad,
      costoUnitario: costoUnitario,
    );
    final sucursalId = state.sucursalId;
    if (sucursalId != null && stockInicial != null && stockInicial > 0) {
      await _repo.registrarEntrada(
        insumoId: id,
        sucursalId: sucursalId,
        cantidad: stockInicial,
        nota: 'Stock inicial',
      );
    }
    if (sucursalId != null && minimo != null && minimo > 0) {
      await _repo.fijarMinimo(
        insumoId: id,
        sucursalId: sucursalId,
        minimo: minimo,
      );
    }
    await cargar();
  }

  Future<void> registrarEntrada(
    String insumoId,
    num cantidad,
    String? nota,
  ) async {
    await _repo.registrarEntrada(
      insumoId: insumoId,
      sucursalId: state.sucursalId!,
      cantidad: cantidad,
      nota: nota,
    );
    await cargar();
  }

  Future<void> ajustar(String insumoId, num contada, String? nota) async {
    await _repo.ajustar(
      insumoId: insumoId,
      sucursalId: state.sucursalId!,
      cantidadContada: contada,
      nota: nota,
    );
    await cargar();
  }

  Future<void> fijarMinimo(String insumoId, num minimo) async {
    await _repo.fijarMinimo(
      insumoId: insumoId,
      sucursalId: state.sucursalId!,
      minimo: minimo,
    );
    await cargar();
  }

  Future<void> definirReceta(String servicioId, Map<String, num> lineas) async {
    await _repo.definirReceta(servicioId: servicioId, lineas: lineas);
    await cargar();
  }
}

/// Kardex de un insumo en una sucursal, cargado al abrir su historial.
final movimientosProvider = FutureProvider.autoDispose
    .family<List<MovimientoInventario>, ({String insumoId, String sucursalId})>(
      (ref, clave) => ref
          .read(inventarioRepositoryProvider)
          .movimientos(insumoId: clave.insumoId, sucursalId: clave.sucursalId),
    );
