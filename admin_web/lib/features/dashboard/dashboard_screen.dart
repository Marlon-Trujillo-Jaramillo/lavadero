import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/resumen_ventas_view.dart';
import 'application/dashboard_controller.dart';

/// Resumen de hoy: saludo, KPIs (ingresos, lavados, ticket promedio, servicio
/// estrella) y ranking de servicios. Consume `/api/v1/agenda/reportes/resumen`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);
    final hoy = DateTime.now();

    return ListView(
      padding: const EdgeInsets.all(LavaderoSpacing.xl),
      children: [
        _Saludo(fecha: hoy),
        const SizedBox(height: LavaderoSpacing.lg),
        switch (state) {
          DashboardState(isLoading: true) => const _DashboardSkeleton(),
          DashboardState(errorMessage: final message?) => ErrorBanner(
            message: message,
            onRetry: controller.cargar,
          ),
          DashboardState(resumen: final resumen?) => ResumenVentasView(
            resumen: resumen,
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// Tarjeta héroe con el saludo según la hora y la fecha de hoy.
class _Saludo extends StatelessWidget {
  const _Saludo({required this.fecha});

  final DateTime fecha;

  String get _saludo => switch (fecha.hour) {
    < 12 => 'Buenos días',
    < 19 => 'Buenas tardes',
    _ => 'Buenas noches',
  };

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return FadeSlideIn(
      child: LavaderoCard(
        gradient: LavaderoGradients.deep,
        padding: const EdgeInsets.all(LavaderoSpacing.xl),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _saludo,
                    style: textTheme.headlineMedium?.copyWith(
                      color: LavaderoColors.white,
                    ),
                  ),
                  const SizedBox(height: LavaderoSpacing.xs),
                  Text(
                    'Así va tu lavadero hoy, ${Formato.fechaCorta(fecha)}.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: LavaderoColors.onBrandMuted,
                    ),
                  ),
                ],
              ),
            ),
            const LavaderoLogo(size: LavaderoSizes.logoLg, onDark: true),
          ],
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: LavaderoSpacing.md,
            runSpacing: LavaderoSpacing.md,
            children: [
              for (var i = 0; i < 4; i++)
                const SizedBox(
                  width: LavaderoSizes.skeletonKpiWidth,
                  child: Skeleton(
                    height: LavaderoSizes.skeletonKpiHeight,
                    radius: LavaderoRadii.lg,
                  ),
                ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.xl),
          const Skeleton(
            height: LavaderoSizes.skeletonPanelHeight,
            radius: LavaderoRadii.lg,
          ),
        ],
      ),
    );
  }
}
