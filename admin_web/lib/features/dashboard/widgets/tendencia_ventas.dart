import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../application/dashboard_controller.dart';

/// Comparativo de hoy contra ayer y tendencia de ingresos de los últimos 7 días.
/// Datos ya cargados por el `DashboardController` (un resumen por día).
class TendenciaVentas extends StatelessWidget {
  const TendenciaVentas({
    super.key,
    required this.serie,
    required this.hoy,
    this.ayer,
  });

  final List<DiaVenta> serie;
  final ResumenVentas hoy;
  final ResumenVentas? ayer;

  static const List<String> _inicialesDia = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final maxIngreso = serie.fold<double>(
      0,
      (max, d) =>
          d.resumen.ingresosTotales > max ? d.resumen.ingresosTotales : max,
    );

    return LavaderoCard(
      padding: const EdgeInsets.all(LavaderoSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Cómo vas vs. ayer', style: textTheme.titleMedium),
          const SizedBox(height: LavaderoSpacing.md),
          Wrap(
            spacing: LavaderoSpacing.sm,
            runSpacing: LavaderoSpacing.sm,
            children: [
              _ChipComparativo(
                etiqueta: 'Ingresos',
                delta: _deltaPorcentaje(
                  hoy.ingresosTotales,
                  ayer?.ingresosTotales,
                ),
              ),
              _ChipComparativo(
                etiqueta: 'Lavados',
                delta: _deltaEntero(
                  hoy.totalReservasCompletadas,
                  ayer?.totalReservasCompletadas,
                ),
              ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.lg),
          Text(
            'Ingresos · últimos 7 días',
            style: textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: LavaderoSpacing.smd),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < serie.length; i++)
                  Expanded(
                    child: _Barra(
                      ratio: maxIngreso == 0
                          ? 0
                          : serie[i].resumen.ingresosTotales / maxIngreso,
                      inicial: _inicialesDia[(serie[i].fecha.weekday - 1) % 7],
                      esHoy: i == serie.length - 1,
                      tieneDatos: serie[i].resumen.ingresosTotales > 0,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _Delta _deltaPorcentaje(double actual, double? previo) {
    if (previo == null || previo == 0) {
      return _Delta(
        texto: actual > 0 ? 'Nuevo' : 'Sin datos',
        tono: _Tono.neutro,
      );
    }
    final pct = ((actual - previo) / previo) * 100;
    final signo = pct > 0 ? '+' : '';
    return _Delta(
      texto: '$signo${pct.toStringAsFixed(0)} %',
      tono: pct > 0
          ? _Tono.positivo
          : (pct < 0 ? _Tono.negativo : _Tono.neutro),
    );
  }

  _Delta _deltaEntero(int actual, int? previo) {
    if (previo == null) {
      return const _Delta(texto: 'Sin datos', tono: _Tono.neutro);
    }
    final diff = actual - previo;
    final signo = diff > 0 ? '+' : '';
    return _Delta(
      texto: '$signo$diff',
      tono: diff > 0
          ? _Tono.positivo
          : (diff < 0 ? _Tono.negativo : _Tono.neutro),
    );
  }
}

enum _Tono { positivo, negativo, neutro }

class _Delta {
  const _Delta({required this.texto, required this.tono});
  final String texto;
  final _Tono tono;
}

class _ChipComparativo extends StatelessWidget {
  const _ChipComparativo({required this.etiqueta, required this.delta});

  final String etiqueta;
  final _Delta delta;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (delta.tono) {
      _Tono.positivo => LavaderoColors.success,
      _Tono.negativo => LavaderoColors.error,
      _Tono.neutro => scheme.onSurfaceVariant,
    };
    final icono = switch (delta.tono) {
      _Tono.positivo => Icons.trending_up_rounded,
      _Tono.negativo => Icons.trending_down_rounded,
      _Tono.neutro => Icons.trending_flat_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.smd,
        vertical: LavaderoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LavaderoRadii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: LavaderoSizes.iconSm, color: color),
          const SizedBox(width: LavaderoSpacing.xs),
          Text('$etiqueta ', style: textTheme.bodySmall),
          Text(
            delta.texto,
            style: textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Barra extends StatelessWidget {
  const _Barra({
    required this.ratio,
    required this.inicial,
    required this.esHoy,
    required this.tieneDatos,
  });

  final double ratio;
  final String inicial;
  final bool esHoy;
  final bool tieneDatos;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colorBarra = esHoy
        ? scheme.primary
        : scheme.primary.withValues(alpha: 0.28);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LavaderoSpacing.xxs),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: FractionallySizedBox(
                heightFactor: tieneDatos ? ratio.clamp(0.06, 1.0) : 0.02,
                widthFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: tieneDatos
                        ? colorBarra
                        : scheme.outlineVariant.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(LavaderoRadii.xs),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: LavaderoSpacing.xs),
          Text(
            inicial,
            style: textTheme.labelSmall?.copyWith(
              color: esHoy ? scheme.primary : scheme.onSurfaceVariant,
              fontWeight: esHoy ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
