import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// Renderiza un [ResumenVentas]: KPIs (ingresos, reservas completadas) + top de servicios más
/// pedidos. Compartido entre `dashboard` y `reports` (mismo shape, dos rangos de fecha distintos)
/// — ver docs/specs/003-dashboard-reportes.md.
class ResumenVentasView extends StatelessWidget {
  const ResumenVentasView({super.key, required this.resumen});

  final ResumenVentas resumen;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Wrap(
          spacing: LavaderoSpacing.md,
          runSpacing: LavaderoSpacing.md,
          children: [
            _KpiCard(
              icon: Icons.payments_outlined,
              label: 'Ingresos',
              value: '\$${resumen.ingresosTotales.toStringAsFixed(0)} ${resumen.moneda}',
            ),
            _KpiCard(
              icon: Icons.local_car_wash_outlined,
              label: 'Reservas completadas',
              value: '${resumen.totalReservasCompletadas}',
            ),
          ],
        ),
        const SizedBox(height: LavaderoSpacing.lg),
        Text('Servicios más pedidos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: LavaderoSpacing.sm),
        if (resumen.serviciosMasPedidos.isEmpty)
          const EmptyState(
            icon: Icons.local_car_wash_outlined,
            title: 'Todavía no hay reservas completadas en este rango',
          )
        else
          Card(
            child: Column(
              children: [
                for (final servicio in resumen.serviciosMasPedidos)
                  ListTile(
                    leading: const Icon(Icons.local_car_wash_outlined),
                    title: Text(servicio.nombreServicio),
                    trailing: Text('${servicio.cantidad}'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: SizedBox(
          width: 220,
          child: Row(
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: LavaderoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    Text(value, style: Theme.of(context).textTheme.headlineSmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
