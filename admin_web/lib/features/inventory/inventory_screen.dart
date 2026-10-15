import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonPlaceholder(
    icon: Icons.inventory_2_rounded,
    headline: 'Controla tus insumos sin hojas de cálculo',
    message:
        'Shampoo, ceras, microfibras y químicos: sabrás cuánto te queda y '
        'cuánto gasta cada servicio.',
    features: [
      ComingSoonFeature(
        icon: Icons.water_drop_outlined,
        title: 'Stock por sucursal',
        message: 'Existencias de cada insumo en cada sede, siempre al día.',
      ),
      ComingSoonFeature(
        icon: Icons.notifications_outlined,
        title: 'Alertas de reposición',
        message: 'Aviso cuando un insumo baje del mínimo que definas.',
      ),
      ComingSoonFeature(
        icon: Icons.calculate_outlined,
        title: 'Costo por lavado',
        message: 'Consumo estimado por servicio para conocer tu margen real.',
      ),
    ],
  );
}
