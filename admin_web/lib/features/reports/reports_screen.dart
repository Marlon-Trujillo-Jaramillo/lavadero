import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import '../shared/widgets/resumen_ventas_view.dart';
import 'application/reports_controller.dart';

/// Rangos rápidos: últimos N días terminando hoy, o uno a medida.
enum _Rango {
  semana(7, '7 días'),
  mes(30, '30 días'),
  trimestre(90, '90 días'),
  personalizado(null, 'Personalizado');

  const _Rango(this.dias, this.etiqueta);

  final int? dias;
  final String etiqueta;
}

/// Igual que `dashboard`, pero con selector de rango de fechas (por defecto, últimos 7 días).
/// Consume el mismo `/api/v1/agenda/reportes/resumen`.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Qué preset corresponde al rango actual (si termina hoy y dura 7/30/90 días).
  _Rango _rangoActual(ReportsState state) {
    final hoy = _soloFecha(DateTime.now());
    if (_soloFecha(state.hasta) != hoy) return _Rango.personalizado;
    final dias = hoy.difference(_soloFecha(state.desde)).inDays + 1;
    for (final rango in _Rango.values) {
      if (rango.dias == dias) return rango;
    }
    return _Rango.personalizado;
  }

  Future<void> _seleccionar(
    BuildContext context,
    WidgetRef ref,
    _Rango rango,
  ) async {
    final controller = ref.read(reportsControllerProvider.notifier);
    final hoy = _soloFecha(DateTime.now());
    final dias = rango.dias;
    if (dias != null) {
      await controller.cambiarRango(
        desde: hoy.subtract(Duration(days: dias - 1)),
        hasta: hoy,
      );
      return;
    }
    final state = ref.read(reportsControllerProvider);
    final primerDia = DateTime(hoy.year - 2, hoy.month, hoy.day);
    final desde = _soloFecha(state.desde);
    final rangoElegido = await showDateRangePicker(
      context: context,
      firstDate: primerDia,
      lastDate: hoy,
      initialDateRange: DateTimeRange(
        start: desde.isBefore(primerDia) ? primerDia : desde,
        end: _soloFecha(state.hasta).isAfter(hoy)
            ? hoy
            : _soloFecha(state.hasta),
      ),
      helpText: 'Elige el rango del reporte',
      saveText: 'Aplicar',
    );
    if (rangoElegido == null) return;
    await controller.cambiarRango(
      desde: rangoElegido.start,
      hasta: rangoElegido.end,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsControllerProvider);
    final controller = ref.read(reportsControllerProvider.notifier);
    final seleccionado = _rangoActual(state);

    return AdminPage(
      toolbar: PageToolbar(
        leading: _EtiquetaRango(desde: state.desde, hasta: state.hasta),
        actions: [
          SegmentedButton<_Rango>(
            showSelectedIcon: false,
            segments: [
              for (final rango in _Rango.values)
                ButtonSegment(
                  value: rango,
                  label: Text(rango.etiqueta),
                  icon: rango == _Rango.personalizado
                      ? const Icon(
                          Icons.date_range_outlined,
                          size: LavaderoSizes.iconSm,
                        )
                      : null,
                ),
            ],
            selected: {seleccionado},
            // Re-tocar el segmento ya seleccionado no dispara este callback: para reabrir el
            // calendario en "Personalizado" está el botón de al lado.
            onSelectionChanged: (seleccion) =>
                _seleccionar(context, ref, seleccion.first),
          ),
          if (seleccionado == _Rango.personalizado)
            IconButton(
              tooltip: 'Cambiar fechas',
              icon: const Icon(Icons.edit_calendar_outlined),
              onPressed: () => _seleccionar(context, ref, _Rango.personalizado),
            ),
        ],
      ),
      body: switch (state) {
        ReportsState(errorMessage: final message?) => Align(
          alignment: Alignment.topCenter,
          child: ErrorBanner(message: message, onRetry: controller.cargar),
        ),
        ReportsState(isLoading: true, resumen: null) =>
          const _ReportesSkeleton(),
        ReportsState(resumen: final resumen?) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.isLoading)
              const LinearProgressIndicator(minHeight: LavaderoSpacing.xxs)
            else
              const SizedBox(height: LavaderoSpacing.xxs),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(
                  top: LavaderoSpacing.sm,
                  bottom: LavaderoSpacing.xl,
                ),
                children: [ResumenVentasView(resumen: resumen)],
              ),
            ),
          ],
        ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}

class _EtiquetaRango extends StatelessWidget {
  const _EtiquetaRango({required this.desde, required this.hasta});

  final DateTime desde;
  final DateTime hasta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dias =
        DateTime(
          hasta.year,
          hasta.month,
          hasta.day,
        ).difference(DateTime(desde.year, desde.month, desde.day)).inDays +
        1;
    final mismoAnio = desde.year == hasta.year;
    final inicio = mismoAnio ? Formato.fechaCorta(desde) : Formato.fecha(desde);
    final fin = mismoAnio ? Formato.fechaCorta(hasta) : Formato.fecha(hasta);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBadge(
          icon: Icons.date_range_rounded,
          size: LavaderoSizes.avatarSm + LavaderoSpacing.xs,
        ),
        const SizedBox(width: LavaderoSpacing.smd),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$inicio – $fin',
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                dias == 1 ? '1 día' : '$dias días',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportesSkeleton extends StatelessWidget {
  const _ReportesSkeleton();

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: LavaderoSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveGrid(
              minItemWidth: 220,
              children: [
                for (var i = 0; i < 4; i++)
                  const Skeleton(
                    height: LavaderoSizes.skeletonKpiHeight,
                    radius: LavaderoRadii.lg,
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
      ),
    );
  }
}
