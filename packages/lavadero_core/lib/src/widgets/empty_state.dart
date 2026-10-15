import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'fade_slide_in.dart';

/// Estado vacío reutilizable (lista sin elementos): icono + título +
/// mensaje + acción opcional. Usado por pantallas de listado en vez de
/// dejar un `ListView` vacío en blanco. El ícono va sobre un halo con el
/// degradado de marca para que el vacío se sienta intencional, no roto.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.minHeight,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Alto mínimo (contenido centrado) cuando el estado vacío vive dentro de
  /// una lista o tarjeta en vez de ocupar toda la pantalla — en lugar de
  /// envolverlo en un `SizedBox(height: ...)` en cada llamador.
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final content = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(LavaderoSpacing.xl),
        child: FadeSlideIn(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LavaderoSizes.emptyStateMaxWidth,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: LavaderoSizes.emptyStateIcon,
                  height: LavaderoSizes.emptyStateIcon,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        scheme.primaryContainer,
                        scheme.secondaryContainer,
                      ],
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: LavaderoSizes.iconXl + LavaderoSpacing.xs,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: LavaderoSpacing.lg),
                Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                if (message != null) ...[
                  const SizedBox(height: LavaderoSpacing.sm),
                  Text(
                    message!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: LavaderoSpacing.lg),
                  FilledButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (minHeight == null) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight!),
      child: content,
    );
  }
}
