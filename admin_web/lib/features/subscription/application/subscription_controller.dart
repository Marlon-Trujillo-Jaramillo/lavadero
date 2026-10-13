import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Suscripción del tenant (ADMIN_TENANT): planes disponibles, inicio del pago en el Web Checkout
/// de Wompi e historial de pagos (`/api/v1/pagos`). El estado de cada pago lo fija el webhook de
/// Wompi en el backend; aquí solo se consulta.
class SubscriptionState {
  const SubscriptionState({
    this.planes = const [],
    this.pagos = const [],
    this.cargandoPlanes = false,
    this.cargandoPagos = false,
    this.errorPlanes,
    this.errorPagos,
    this.errorPago,
    this.pagandoPlanId,
    this.ultimoCheckout,
  });

  final List<SubscriptionPlan> planes;
  final List<Pago> pagos;
  final bool cargandoPlanes;
  final bool cargandoPagos;
  final String? errorPlanes;
  final String? errorPagos;

  /// Error al iniciar un pago (p. ej. pasarela no configurada).
  final String? errorPago;

  /// Plan cuyo checkout se está preparando (loading en su botón).
  final String? pagandoPlanId;

  /// Último checkout abierto: se ofrece reabrirlo por si el navegador bloqueó la pestaña.
  final CheckoutPago? ultimoCheckout;

  SubscriptionState copyWith({
    List<SubscriptionPlan>? planes,
    List<Pago>? pagos,
    bool? cargandoPlanes,
    bool? cargandoPagos,
    String? errorPlanes,
    bool clearErrorPlanes = false,
    String? errorPagos,
    bool clearErrorPagos = false,
    String? errorPago,
    bool clearErrorPago = false,
    String? pagandoPlanId,
    bool clearPagandoPlanId = false,
    CheckoutPago? ultimoCheckout,
    bool clearUltimoCheckout = false,
  }) {
    return SubscriptionState(
      planes: planes ?? this.planes,
      pagos: pagos ?? this.pagos,
      cargandoPlanes: cargandoPlanes ?? this.cargandoPlanes,
      cargandoPagos: cargandoPagos ?? this.cargandoPagos,
      errorPlanes: clearErrorPlanes ? null : (errorPlanes ?? this.errorPlanes),
      errorPagos: clearErrorPagos ? null : (errorPagos ?? this.errorPagos),
      errorPago: clearErrorPago ? null : (errorPago ?? this.errorPago),
      pagandoPlanId: clearPagandoPlanId
          ? null
          : (pagandoPlanId ?? this.pagandoPlanId),
      ultimoCheckout: clearUltimoCheckout
          ? null
          : (ultimoCheckout ?? this.ultimoCheckout),
    );
  }
}

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, SubscriptionState>(
      SubscriptionController.new,
    );

class SubscriptionController extends Notifier<SubscriptionState> {
  static const mensajePasarelaNoConfigurada =
      'Los pagos en línea todavía no están habilitados para tu lavadero. '
      'Intenta más tarde o escríbenos para activar tu plan.';

  static const mensajePlanesSinPermiso =
      'Tu cuenta todavía no puede consultar el catálogo de planes. '
      'Escríbenos y te ayudamos a elegir el tuyo.';

  static const mensajeCheckoutBloqueado =
      'Tu navegador no abrió la ventana de pago (¿bloqueador de ventanas emergentes?). '
      'Pulsa "Reintentar" para abrirla de nuevo.';

  @override
  SubscriptionState build() {
    Future.microtask(cargar);
    return const SubscriptionState(cargandoPlanes: true, cargandoPagos: true);
  }

  Future<void> cargar() => Future.wait([cargarPlanes(), cargarPagos()]);

  Future<void> cargarPlanes() async {
    state = state.copyWith(cargandoPlanes: true, clearErrorPlanes: true);
    try {
      final planes = [
        ...await ref.read(tenantRepositoryProvider).listarPlanesDisponibles(),
      ]..sort((a, b) => a.precio.compareTo(b.precio));
      state = state.copyWith(planes: planes, cargandoPlanes: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        cargandoPlanes: false,
        errorPlanes: e.isForbidden ? mensajePlanesSinPermiso : e.message,
      );
    }
  }

  Future<void> cargarPagos() async {
    state = state.copyWith(cargandoPagos: true, clearErrorPagos: true);
    try {
      final pagos = await ref.read(pagoRepositoryProvider).listar();
      state = state.copyWith(pagos: pagos, cargandoPagos: false);
    } on ApiException catch (e) {
      state = state.copyWith(cargandoPagos: false, errorPagos: e.message);
    }
  }

  /// Crea el pago PENDIENTE en el backend y abre el checkout de Wompi en otra pestaña. El monto
  /// lo decide el backend a partir del plan, nunca el cliente.
  Future<void> pagar(String subscriptionPlanId) async {
    if (state.pagandoPlanId != null) return;
    state = state.copyWith(
      pagandoPlanId: subscriptionPlanId,
      clearErrorPago: true,
      clearUltimoCheckout: true,
    );
    try {
      final checkout = await ref
          .read(pagoRepositoryProvider)
          .iniciarPagoSuscripcion(subscriptionPlanId: subscriptionPlanId);
      state = state.copyWith(ultimoCheckout: checkout);
      final abierto = await _abrir(checkout.uri);
      if (!abierto) state = state.copyWith(errorPago: mensajeCheckoutBloqueado);
      // El pago recién creado aparece como pendiente en el historial.
      await cargarPagos();
    } on ApiException catch (e) {
      state = state.copyWith(errorPago: _mensajePago(e));
    } finally {
      state = state.copyWith(clearPagandoPlanId: true);
    }
  }

  Future<void> reabrirCheckout() async {
    final checkout = state.ultimoCheckout;
    if (checkout == null) return;
    final abierto = await _abrir(checkout.uri);
    state = abierto
        ? state.copyWith(clearErrorPago: true)
        : state.copyWith(errorPago: mensajeCheckoutBloqueado);
  }

  /// `url_launcher` puede lanzar (`PlatformException`, URL rechazada por el navegador...): se
  /// trata igual que una pestaña bloqueada, con la opción de reintentar, en vez de dejar escapar
  /// la excepción y el botón en loading.
  Future<bool> _abrir(Uri uri) async {
    try {
      return await ref.read(abrirUrlExternaProvider)(uri);
    } on Object {
      return false;
    }
  }

  void descartarErrorPago() => state = state.copyWith(clearErrorPago: true);

  /// El backend responde 400 "Los pagos todavía no están configurados... (falta la cuenta de
  /// Wompi)" cuando el ambiente no tiene llaves: se traduce a algo entendible para el dueño.
  String _mensajePago(ApiException e) {
    final mensaje = e.message.toLowerCase();
    final pasarelaNoConfigurada =
        e.isValidationError &&
        (mensaje.contains('wompi') || mensaje.contains('configurad'));
    return pasarelaNoConfigurada ? mensajePasarelaNoConfigurada : e.message;
  }
}
