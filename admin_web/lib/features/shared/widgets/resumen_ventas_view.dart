import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// Renderiza un [ResumenVentas]: KPIs (ingresos, reservas completadas, ticket
/// promedio, servicio estrella) + ranking de servicios más pedidos con barras
/// proporcionales. Compartido entre `dashboard` y `reports` (mismo shape, dos
/// rangos de fecha distintos) — ver docs/specs/003-dashboard-reportes.md.
///
/// No es scrollable por sí mismo: el llamador lo pone dentro de su
/// `ListView`/`SingleChildScrollView`.
class ResumenVentasView extends StatelessWidget {
  const ResumenVentasView({super.key, required this.resumen});

  final ResumenVentas resumen;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final completadas = resumen.totalReservasCompletadas;
    final ticketPromedio = completadas == 0
        ? 0
        : resumen.ingresosTotales / completadas;
    final estrella = resumen.serviciosMasPedidos.isEmpty
        ? '—'
        : resumen.serviciosMasPedidos.first.nombreServicio;

    final kpis = [
      StatCard(
        icon: Icons.payments_outlined,
        label: 'Ingresos',
        value: Formato.moneda(resumen.ingresosTotales, resumen.moneda),
        caption: resumen.moneda,
        color: scheme.primary,
      ),
      StatCard(
        icon: Icons.local_car_wash_outlined,
        label: 'Lavados completados',
        value: '$completadas',
        caption: completadas == 1 ? 'reserva' : 'reservas',
        color: LavaderoColors.aqua,
      ),
      StatCard(
        icon: Icons.receipt_long_outlined,
        label: 'Ticket promedio',
        value: Formato.moneda(ticketPromedio, resumen.moneda),
        caption: 'por lavado',
        color: LavaderoColors.success,
      ),
      StatCard(
        icon: Icons.star_outline_rounded,
        label: 'Servicio estrella',
        value: estrella,
        caption: 'el más pedido',
        color: LavaderoColors.warning,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columnas = constraints.maxWidth >= LavaderoBreakpoints.kpis4
                ? 4
                : constraints.maxWidth >= LavaderoBreakpoints.kpis2
                ? 2
                : 1;
            const gap = LavaderoSpacing.md;
            final ancho =
                (constraints.maxWidth - gap * (columnas - 1)) / columnas;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < kpis.length; i++)
                  SizedBox(
                    width: ancho,
                    child: FadeSlideIn(index: i, child: kpis[i]),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: LavaderoSpacing.xl),
        const SectionHeader(
          title: 'Servicios más pedidos',
          subtitle: 'Reservas completadas por servicio',
        ),
        if (resumen.serviciosMasPedidos.isEmpty)
          const LavaderoCard(
            child: EmptyState(
              minHeight: LavaderoSizes.emptyStateMinHeight,
              icon: Icons.local_car_wash_outlined,
              title: 'Aún no hay lavados completados',
              message:
                  'Cuando tu equipo complete reservas en este rango, '
                  'verás aquí qué servicios se piden más.',
            ),
          )
        else
          FadeSlideIn(
            index: kpis.length,
            child: _RankingServicios(servicios: resumen.serviciosMasPedidos),
          ),
      ],
    );
  }
}

class _RankingServicios extends StatelessWidget {
  const _RankingServicios({required this.servicios});

  final List<ServicioPopular> servicios;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final maximo = servicios
        .map((s) => s.cantidad)
        .fold<int>(1, (a, b) => b > a ? b : a);
    return LavaderoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.lg,
        vertical: LavaderoSpacing.sm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < servicios.length; i++) ...[
            if (i > 0) const Divider(height: LavaderoSizes.hairline),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: LavaderoSizes.avatarSm,
                    height: LavaderoSizes.avatarSm,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: i == 0 ? LavaderoGradients.brandStrong : null,
                      color: i == 0 ? null : scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(LavaderoRadii.sm),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: i == 0
                            ? LavaderoColors.white
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: LavaderoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servicios[i].nombreServicio,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: LavaderoSpacing.sm),
                        _BarraProporcional(
                          fraccion: servicios[i].cantidad / maximo,
                          destacada: i == 0,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: LavaderoSpacing.lg),
                  Text(
                    '${servicios[i].cantidad}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFeatures: LavaderoTypography.tabular,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BarraProporcional extends StatelessWidget {
  const _BarraProporcional({required this.fraccion, required this.destacada});

  final double fraccion;
  final bool destacada;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(LavaderoRadii.full),
      child: SizedBox(
        height: LavaderoSpacing.sm - LavaderoSpacing.xxs,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: scheme.surfaceContainer)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraccion),
              duration: LavaderoMotion.slow,
              curve: LavaderoMotion.emphasized,
              builder: (context, value, _) => FractionallySizedBox(
                widthFactor: value.clamp(0.02, 1),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: destacada ? LavaderoGradients.brand : null,
                    color: destacada
                        ? null
                        : scheme.primary.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(LavaderoRadii.full),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
