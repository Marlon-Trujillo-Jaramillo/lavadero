import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Pill translúcida para usar ENCIMA de un degradado de marca (tarjetas
/// héroe): blanco con transparencia, ícono opcional y texto blanco.
class GlassPill extends StatelessWidget {
  const GlassPill({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.smd,
        vertical: LavaderoSpacing.xs + LavaderoSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: LavaderoColors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(LavaderoRadii.full),
        border: Border.all(color: LavaderoColors.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: LavaderoSizes.iconSm, color: LavaderoColors.white),
            const SizedBox(width: LavaderoSpacing.xs + LavaderoSpacing.xxs),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: LavaderoColors.white),
          ),
        ],
      ),
    );
  }
}
