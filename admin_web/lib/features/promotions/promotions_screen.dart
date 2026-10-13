import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

class PromotionsScreen extends StatelessWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonPlaceholder(
    icon: Icons.local_offer_rounded,
    headline: 'Campañas que llenan tus horas valle',
    message:
        'Crea descuentos y cupones para atraer clientes en los días y '
        'horarios con menos movimiento.',
    features: [
      ComingSoonFeature(
        icon: Icons.confirmation_number_outlined,
        title: 'Cupones de descuento',
        message:
            'Códigos por porcentaje o monto fijo, con fecha de vencimiento.',
      ),
      ComingSoonFeature(
        icon: Icons.schedule_outlined,
        title: 'Precios por horario',
        message: 'Tarifas especiales automáticas para horas de baja demanda.',
      ),
      ComingSoonFeature(
        icon: Icons.insights_outlined,
        title: 'Resultados por campaña',
        message: 'Cuántas reservas e ingresos generó cada promoción.',
      ),
    ],
  );
}
