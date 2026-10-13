import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Ícono dentro de un cuadrado redondeado tintado con su propio color.
/// Es el "acento" visual de filas y KPIs.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.color,
    this.size = LavaderoSizes.avatarMd,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, size: size * 0.5, color: tint),
    );
  }
}
