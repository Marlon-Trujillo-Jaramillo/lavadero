import 'package:flutter/material.dart';

/// Placeholder de navegación para secciones de negocio aún no implementadas
/// (dashboard, employees, catalog_pricing, inventory, branches, crm,
/// reports, promotions, tenant_admin) — se implementan en fases posteriores.
class ComingSoonPlaceholder extends StatelessWidget {
  const ComingSoonPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.construction_outlined, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Próximamente',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
