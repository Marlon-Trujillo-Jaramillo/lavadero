import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Botón principal que se deshabilita y muestra un spinner mientras
/// [isLoading] es `true`, sin cambiar de tamaño (el contenido se cruza con
/// el spinner en vez de saltar). Usado en login/registro y formularios.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
    this.icon,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = icon == null
        ? child
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: LavaderoSizes.iconMd),
              const SizedBox(width: LavaderoSpacing.sm),
              Flexible(child: child),
            ],
          );
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        disabledBackgroundColor: isLoading
            ? scheme.primary.withValues(alpha: 0.85)
            : null,
        disabledForegroundColor: isLoading ? scheme.onPrimary : null,
      ),
      child: AnimatedSwitcher(
        duration: LavaderoMotion.fast,
        child: isLoading
            ? SizedBox.square(
                key: const ValueKey('loading'),
                dimension: LavaderoSizes.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: scheme.onPrimary,
                ),
              )
            : KeyedSubtree(key: const ValueKey('label'), child: label),
      ),
    );
  }
}
