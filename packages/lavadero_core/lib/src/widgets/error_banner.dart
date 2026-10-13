import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Banner de error compacto para mostrar el `message` de un `ApiException`
/// (u otro error), con opción de descartarlo o reintentar.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedSize(
      duration: LavaderoMotion.normal,
      curve: LavaderoMotion.emphasized,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          LavaderoSpacing.md,
          LavaderoSpacing.smd,
          LavaderoSpacing.sm,
          LavaderoSpacing.smd,
        ),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(LavaderoRadii.md),
          border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: LavaderoSizes.iconMd,
              color: scheme.error,
            ),
            const SizedBox(width: LavaderoSpacing.smd),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onErrorContainer,
                ),
                child: const Text('Reintentar'),
              ),
            if (onDismiss != null)
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: LavaderoSizes.iconMd,
                  color: scheme.onErrorContainer,
                ),
                onPressed: onDismiss,
                tooltip: 'Cerrar',
              ),
          ],
        ),
      ),
    );
  }
}
