import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/resumen_ventas_view.dart';
import 'application/dashboard_controller.dart';

/// KPIs de hoy: ingresos, reservas completadas, servicios más pedidos. Consume
/// `/api/v1/agenda/reportes/resumen`.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(LavaderoSpacing.md),
      child: switch (state) {
        DashboardState(isLoading: true) => const Center(child: CircularProgressIndicator()),
        DashboardState(errorMessage: final message?) => ListView(
            children: [ErrorBanner(message: message)],
          ),
        DashboardState(resumen: final resumen?) => ResumenVentasView(resumen: resumen),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
