import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/resumen_ventas_view.dart';
import 'application/reports_controller.dart';

/// Igual que `dashboard`, pero con selector de rango de fechas (por defecto, últimos 7 días).
/// Consume el mismo `/api/v1/agenda/reportes/resumen`.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  Future<void> _elegirRango(BuildContext context, WidgetRef ref, ReportsState state) async {
    final rango = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: state.desde, end: state.hasta),
    );
    if (rango == null) return;
    await ref
        .read(reportsControllerProvider.notifier)
        .cambiarRango(desde: rango.start, hasta: rango.end);
  }

  String _formatearFecha(DateTime fecha) {
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reportsControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(LavaderoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatearFecha(state.desde)} — ${_formatearFecha(state.hasta)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _elegirRango(context, ref, state),
                icon: const Icon(Icons.date_range_outlined),
                label: const Text('Elegir rango'),
              ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.md),
          Expanded(
            child: switch (state) {
              ReportsState(isLoading: true) => const Center(child: CircularProgressIndicator()),
              ReportsState(errorMessage: final message?) => ListView(
                  children: [ErrorBanner(message: message)],
                ),
              ReportsState(resumen: final resumen?) => ResumenVentasView(resumen: resumen),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
    );
  }
}
