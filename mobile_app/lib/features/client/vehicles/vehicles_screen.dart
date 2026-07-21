import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon_placeholder.dart';

/// Placeholder de navegación — lógica de negocio pendiente (fase posterior).
class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(title: 'Mis vehículos');
  }
}
