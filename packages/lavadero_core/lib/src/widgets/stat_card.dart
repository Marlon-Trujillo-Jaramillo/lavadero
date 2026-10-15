import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'icon_badge.dart';
import 'lavadero_card.dart';

/// KPI: ícono en un badge tintado, etiqueta, valor grande con dígitos
/// tabulares y una línea opcional de contexto ("vs. ayer", "hoy"...).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LavaderoCard(
      onTap: onTap,
      padding: const EdgeInsets.all(LavaderoSpacing.lg - LavaderoSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconBadge(icon: icon, color: color ?? scheme.primary),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_outward_rounded,
                  size: LavaderoSizes.iconMd,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.md),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: LavaderoSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFeatures: LavaderoTypography.tabular,
              ),
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: LavaderoSpacing.xs),
            Text(
              caption!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
