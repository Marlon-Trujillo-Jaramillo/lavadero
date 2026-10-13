import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'pressable.dart';

/// Superficie base de la UI: fondo de tarjeta, borde de 1px y sombra difusa.
/// Con [onTap] se vuelve tocable (escala al presionar). Con [gradient] se usa
/// como tarjeta héroe de marca (texto en blanco — el llamador lo decide).
class LavaderoCard extends StatelessWidget {
  const LavaderoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(LavaderoSpacing.md),
    this.onTap,
    this.gradient,
    this.color,
    this.radius = LavaderoRadii.lg,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final double radius;

  /// Sin sombra cuando la tarjeta vive dentro de otra superficie.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(radius);
    final decorated = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? scheme.surfaceContainerLow) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: gradient == null
            ? Border.all(color: scheme.outlineVariant)
            : null,
        boxShadow: !elevated
            ? null
            : gradient != null
            ? LavaderoShadows.glow(LavaderoColors.ocean)
            : LavaderoShadows.soft(scheme.brightness),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Padding(padding: padding, child: child),
      ),
    );
    if (onTap == null) return decorated;
    return Pressable(
      onTap: onTap,
      borderRadius: borderRadius,
      child: decorated,
    );
  }
}
