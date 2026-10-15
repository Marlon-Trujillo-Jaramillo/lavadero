import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

class CrmScreen extends StatelessWidget {
  const CrmScreen({super.key});

  @override
  Widget build(BuildContext context) => const ComingSoonPlaceholder(
    icon: Icons.groups_rounded,
    headline: 'Conoce a tus clientes y haz que vuelvan',
    message:
        'Historial de visitas, vehículos y gasto de cada cliente, para '
        'fidelizarlos con el mensaje justo en el momento justo.',
    features: [
      ComingSoonFeature(
        icon: Icons.person_search_outlined,
        title: 'Ficha de cliente',
        message: 'Visitas, vehículos, servicios favoritos y gasto acumulado.',
      ),
      ComingSoonFeature(
        icon: Icons.loyalty_outlined,
        title: 'Clientes frecuentes y en riesgo',
        message: 'Detecta a quién no ves hace tiempo antes de perderlo.',
      ),
      ComingSoonFeature(
        icon: Icons.campaign_outlined,
        title: 'Mensajes de recordatorio',
        message:
            'Recordatorios de mantenimiento y agradecimientos post-servicio.',
      ),
    ],
  );
}
