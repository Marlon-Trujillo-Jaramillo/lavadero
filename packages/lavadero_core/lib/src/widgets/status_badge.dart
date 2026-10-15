import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Pill de color + punto + texto para representar un estado (estado de
/// `Reserva`, activo/inactivo de `Servicio`, etc.). El color lo decide el
/// llamador (cada dominio conoce el mapeo estado→color); este widget solo da
/// la forma visual consistente.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.sm + LavaderoSpacing.xxs,
        vertical: LavaderoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LavaderoRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: LavaderoSpacing.sm - LavaderoSpacing.xxs,
            height: LavaderoSpacing.sm - LavaderoSpacing.xxs,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: LavaderoSpacing.xs + LavaderoSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
