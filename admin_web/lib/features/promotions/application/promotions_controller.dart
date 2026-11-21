import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../../auth/application/admin_auth_controller.dart';

class PromotionsState {
  const PromotionsState({
    this.promociones = const [],
    this.isLoading = false,
    this.desactivandoId,
    this.errorMessage,
  });

  final List<Promocion> promociones;
  final bool isLoading;
  final String? desactivandoId;
  final String? errorMessage;

  PromotionsState copyWith({
    List<Promocion>? promociones,
    bool? isLoading,
    String? desactivandoId,
    bool limpiarDesactivando = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PromotionsState(
      promociones: promociones ?? this.promociones,
      isLoading: isLoading ?? this.isLoading,
      desactivandoId: limpiarDesactivando
          ? null
          : (desactivandoId ?? this.desactivandoId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Crear y desactivar es solo del dueño (ADMIN_TENANT); el admin de
/// sucursal ve las promociones y sus resultados. Provider aparte para poder
/// fijarlo en tests sin levantar la sesión.
final puedeGestionarPromocionesProvider = Provider<bool>((ref) {
  final auth = ref.watch(adminAuthControllerProvider);
  return auth is AdminAuthAuthenticated &&
      auth.user.hasRole(UserRole.adminTenant);
});

final promotionsControllerProvider =
    NotifierProvider<PromotionsController, PromotionsState>(
      PromotionsController.new,
    );

class PromotionsController extends Notifier<PromotionsState> {
  @override
  PromotionsState build() {
    Future.microtask(cargar);
    return const PromotionsState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final promociones = await ref.read(promocionRepositoryProvider).listar();
      state = state.copyWith(promociones: promociones, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }

  /// Lanza [ApiException] para que el formulario muestre el motivo (p. ej.
  /// "Ya tienes un cupón activo con el código HOLA").
  Future<void> crear({
    required String nombre,
    required TipoPromocion tipo,
    required TipoDescuento tipoDescuento,
    required num valorDescuento,
    required DateTime vigenteDesde,
    required DateTime vigenteHasta,
    String? codigo,
    int? usosMaximos,
    List<DiaSemana> dias = const [],
    String? horaDesde,
    String? horaHasta,
  }) async {
    final creada = await ref
        .read(promocionRepositoryProvider)
        .crear(
          nombre: nombre,
          tipo: tipo,
          tipoDescuento: tipoDescuento,
          valorDescuento: valorDescuento,
          vigenteDesde: vigenteDesde,
          vigenteHasta: vigenteHasta,
          codigo: codigo,
          usosMaximos: usosMaximos,
          dias: dias,
          horaDesde: horaDesde,
          horaHasta: horaHasta,
        );
    state = state.copyWith(promociones: [creada, ...state.promociones]);
  }

  Future<void> desactivar(String promocionId) async {
    state = state.copyWith(desactivandoId: promocionId, clearError: true);
    try {
      await ref.read(promocionRepositoryProvider).desactivar(promocionId);
      await cargar();
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    } finally {
      state = state.copyWith(limpiarDesactivando: true);
    }
  }

  void descartarError() => state = state.copyWith(clearError: true);
}
