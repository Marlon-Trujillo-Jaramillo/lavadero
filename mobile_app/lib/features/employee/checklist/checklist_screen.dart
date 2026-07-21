import 'package:flutter/material.dart';

import '../../shared/widgets/coming_soon_placeholder.dart';

/// Placeholder de navegación — lógica de negocio pendiente (fase posterior).
class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonPlaceholder(title: 'Checklist de servicio');
  }
}
