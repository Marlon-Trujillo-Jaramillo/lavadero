import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Banner de error compacto para mostrar el `message` de un `ApiException`
/// (u otro error) debajo de un formulario, con opción de descartarlo.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.md,
        vertical: LavaderoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(LavaderoRadii.sm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer),
          const SizedBox(width: LavaderoSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, color: scheme.onErrorContainer),
              onPressed: onDismiss,
              tooltip: 'Cerrar',
            ),
        ],
      ),
    );
  }
}
