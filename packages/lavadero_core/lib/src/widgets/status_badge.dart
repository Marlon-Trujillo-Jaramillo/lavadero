import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Pill de color + texto para representar un estado (estado de `Reserva`,
/// activo/inactivo de `Servicio`, etc.). El color lo decide el llamador
/// (cada dominio conoce el mapeo estado→color); este widget solo da la
/// forma visual consistente.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.sm,
        vertical: LavaderoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(LavaderoRadii.full),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
