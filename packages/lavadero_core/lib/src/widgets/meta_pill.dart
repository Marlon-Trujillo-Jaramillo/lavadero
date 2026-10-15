import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Dato secundario compacto (ícono + texto) en una pastilla neutra:
/// duración de un servicio, capacidad de una sucursal, sucursal de un
/// empleado... A diferencia de `StatusBadge`, no representa un estado sino
/// un atributo, así que no lleva color semántico salvo que se pida [color].
class MetaPill extends StatelessWidget {
  const MetaPill({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = color ?? scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.sm,
        vertical: LavaderoSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color?.withValues(alpha: 0.10) ?? scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(LavaderoRadii.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: LavaderoSizes.iconSm, color: foreground),
          const SizedBox(width: LavaderoSpacing.xs + LavaderoSpacing.xxs),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontFeatures: LavaderoTypography.tabular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
