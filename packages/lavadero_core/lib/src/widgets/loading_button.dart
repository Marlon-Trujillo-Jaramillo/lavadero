import 'package:flutter/material.dart';

/// Botón elevado que se deshabilita y muestra un spinner mientras
/// [isLoading] es `true`. Usado en login/registro (y reutilizable a futuro).
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.child,
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            )
          : child,
    );
  }
}
