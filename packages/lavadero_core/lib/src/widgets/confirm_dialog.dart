import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'icon_badge.dart';

/// Confirmación previa a una acción (sobre todo destructiva: cancelar una
/// reserva, desactivar un servicio...). Usar con [ConfirmDialog.show], que
/// devuelve `true` solo si el usuario confirma.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirmar',
    this.cancelLabel = 'Volver',
    this.icon,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    String cancelLabel = 'Volver',
    IconData? icon,
    bool destructive = false,
  }) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        icon: icon,
        destructive: destructive,
      ),
    );
    return confirmado ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tint = destructive ? scheme.error : scheme.primary;
    return Dialog(
      insetPadding: const EdgeInsets.all(LavaderoSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LavaderoSizes.dialogWidth),
        child: Padding(
          padding: const EdgeInsets.all(LavaderoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(
                icon:
                    icon ??
                    (destructive
                        ? Icons.warning_amber_rounded
                        : Icons.help_outline_rounded),
                color: tint,
                size: LavaderoSizes.avatarLg,
              ),
              const SizedBox(height: LavaderoSpacing.md),
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: LavaderoSpacing.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LavaderoSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(cancelLabel),
                  ),
                  const SizedBox(width: LavaderoSpacing.sm),
                  FilledButton(
                    style: destructive
                        ? FilledButton.styleFrom(
                            backgroundColor: scheme.error,
                            foregroundColor: scheme.onError,
                          )
                        : null,
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
