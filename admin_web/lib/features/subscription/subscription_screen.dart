import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import '../shared/widgets/plan_pricing_card.dart';
import 'application/subscription_controller.dart';

/// Suscripción del lavadero (ADMIN_TENANT): elegir un plan, pagarlo en el Web Checkout de Wompi
/// y ver el historial de pagos con su estado (lo confirma el webhook de Wompi en el backend).
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionControllerProvider);
    final controller = ref.read(subscriptionControllerProvider.notifier);
    final checkoutBloqueado =
        state.errorPago == SubscriptionController.mensajeCheckoutBloqueado &&
        state.ultimoCheckout != null;

    return AdminPage(
      toolbar: PageToolbar(
        leading: const _AvisoPagoSeguro(),
        actions: [
          OutlinedButton.icon(
            onPressed: state.cargandoPlanes || state.cargandoPagos
                ? null
                : controller.cargar,
            icon: const Icon(Icons.refresh_rounded, size: LavaderoSizes.iconMd),
            label: const Text('Actualizar'),
          ),
        ],
      ),
      banner: state.errorPago != null
          ? ErrorBanner(
              message: state.errorPago!,
              onRetry: checkoutBloqueado ? controller.reabrirCheckout : null,
              onDismiss: controller.descartarErrorPago,
            )
          : null,
      body: ListView(
        padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
        children: [
          const SectionHeader(
            title: 'Elige tu plan',
            subtitle: 'Tu plan se activa en cuanto Wompi aprueba el pago.',
          ),
          _Planes(state: state, controller: controller),
          const SizedBox(height: LavaderoSpacing.xl),
          SectionHeader(
            title: 'Historial de pagos',
            subtitle:
                'Los pagos pendientes se actualizan solos cuando Wompi los confirma.',
            trailing: TextButton.icon(
              onPressed: state.cargandoPagos ? null : controller.cargarPagos,
              icon: const Icon(
                Icons.refresh_rounded,
                size: LavaderoSizes.iconSm,
              ),
              label: const Text('Actualizar'),
            ),
          ),
          _Historial(state: state, controller: controller),
        ],
      ),
    );
  }
}

class _AvisoPagoSeguro extends StatelessWidget {
  const _AvisoPagoSeguro();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const IconBadge(
          icon: Icons.verified_user_outlined,
          color: LavaderoColors.success,
          size: LavaderoSizes.avatarSm + LavaderoSpacing.xs,
        ),
        const SizedBox(width: LavaderoSpacing.smd),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pagos seguros con Wompi',
                style: theme.textTheme.titleSmall,
              ),
              Text(
                'Tarjeta, PSE y más medios. Nunca vemos ni guardamos tus datos de pago.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Planes extends StatelessWidget {
  const _Planes({required this.state, required this.controller});

  final SubscriptionState state;
  final SubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    if (state.cargandoPlanes && state.planes.isEmpty) {
      return const CardGridSkeleton(
        itemCount: 3,
        itemHeight: PlanPricingCard.alturaEsqueleto,
        minItemWidth: 260,
      );
    }
    if (state.errorPlanes != null) {
      return ErrorBanner(
        message: state.errorPlanes!,
        onRetry: controller.cargarPlanes,
      );
    }
    if (state.planes.isEmpty) {
      return const LavaderoCard(
        child: EmptyState(
          minHeight: LavaderoSizes.emptyStateMinHeight,
          icon: Icons.workspace_premium_outlined,
          title: 'Aún no hay planes disponibles',
          message: 'Pronto podrás elegir y pagar tu plan desde aquí.',
        ),
      );
    }
    // Ordenados por precio: se destaca el del medio (o el más completo si hay dos).
    final destacado = state.planes.length >= 2 ? state.planes.length ~/ 2 : -1;
    return ResponsiveGrid(
      minItemWidth: 260,
      maxColumns: 3,
      children: [
        for (var i = 0; i < state.planes.length; i++)
          PlanPricingCard(
            plan: state.planes[i],
            destacado: i == destacado,
            accion: _BotonPagar(
              plan: state.planes[i],
              pagando: state.pagandoPlanId == state.planes[i].id,
              habilitado: state.pagandoPlanId == null,
              onPagar: () => controller.pagar(state.planes[i].id),
            ),
          ),
      ],
    );
  }
}

class _BotonPagar extends StatelessWidget {
  const _BotonPagar({
    required this.plan,
    required this.pagando,
    required this.habilitado,
    required this.onPagar,
  });

  final SubscriptionPlan plan;
  final bool pagando;
  final bool habilitado;
  final VoidCallback onPagar;

  @override
  Widget build(BuildContext context) {
    final gratis = plan.precio <= 0;
    return LoadingButton(
      isLoading: pagando,
      icon: gratis ? Icons.check_rounded : Icons.lock_outline_rounded,
      onPressed: gratis || !habilitado ? null : onPagar,
      child: Text(gratis ? 'Sin costo' : 'Pagar con Wompi'),
    );
  }
}

extension _PagoEstadoVisual on PagoEstado {
  String get etiqueta => switch (this) {
    PagoEstado.pendiente => 'Pendiente',
    PagoEstado.aprobado => 'Aprobado',
    PagoEstado.rechazado => 'Rechazado',
  };

  Color get color => switch (this) {
    PagoEstado.pendiente => LavaderoColors.warning,
    PagoEstado.aprobado => LavaderoColors.success,
    PagoEstado.rechazado => LavaderoColors.error,
  };

  IconData get icono => switch (this) {
    PagoEstado.pendiente => Icons.hourglass_top_rounded,
    PagoEstado.aprobado => Icons.check_circle_outline_rounded,
    PagoEstado.rechazado => Icons.cancel_outlined,
  };
}

class _Historial extends StatelessWidget {
  const _Historial({required this.state, required this.controller});

  final SubscriptionState state;
  final SubscriptionController controller;

  @override
  Widget build(BuildContext context) {
    if (state.cargandoPagos && state.pagos.isEmpty) {
      return const SkeletonList.inline();
    }
    if (state.errorPagos != null) {
      return ErrorBanner(
        message: state.errorPagos!,
        onRetry: controller.cargarPagos,
      );
    }
    if (state.pagos.isEmpty) {
      return const LavaderoCard(
        child: EmptyState(
          minHeight: LavaderoSizes.emptyStateMinHeight,
          icon: Icons.receipt_long_outlined,
          title: 'Aún no tienes pagos',
          message: 'Cuando pagues tu plan, verás aquí cada cobro y su estado.',
        ),
      );
    }
    final nombresPlanes = {for (final p in state.planes) p.id: p.nombre};
    return FadeSlideIn(
      child: LavaderoCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < state.pagos.length; i++) ...[
              if (i > 0) const Divider(height: LavaderoSizes.hairline),
              _PagoFila(
                pago: state.pagos[i],
                nombrePlan: nombresPlanes[state.pagos[i].subscriptionPlanId],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PagoFila extends StatelessWidget {
  const _PagoFila({required this.pago, required this.nombrePlan});

  final Pago pago;
  final String? nombrePlan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.lg,
        vertical: LavaderoSpacing.smd,
      ),
      child: Row(
        children: [
          IconBadge(icon: pago.estado.icono, color: pago.estado.color),
          const SizedBox(width: LavaderoSpacing.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombrePlan == null ? 'Suscripción' : 'Plan $nombrePlan',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${Formato.fechaHora(pago.creadoEn.toLocal())} · Ref. ${pago.referencia}',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LavaderoSpacing.md),
          Text(
            Formato.moneda(pago.monto, pago.moneda),
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: LavaderoTypography.tabular,
            ),
          ),
          const SizedBox(width: LavaderoSpacing.md),
          StatusBadge(label: pago.estado.etiqueta, color: pago.estado.color),
        ],
      ),
    );
  }
}
