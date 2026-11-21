import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'error_banner.dart';
import 'icon_badge.dart';
import 'loading_button.dart';

/// Diálogo de formulario estándar (alta/edición): encabezado con ícono,
/// título y subtítulo; campos separados con aire; error del servidor arriba
/// de las acciones; "Cancelar" + botón principal con loading. Ancho fijo
/// [LavaderoSizes.dialogWidth] y scroll propio si la ventana es baja.
///
/// El llamador conserva la lógica (validación, llamada al controller,
/// `Navigator.pop`); este widget solo da la forma visual consistente.
class LavaderoFormDialog extends StatelessWidget {
  const LavaderoFormDialog({
    super.key,
    required this.title,
    required this.formKey,
    required this.fields,
    required this.onSubmit,
    required this.isLoading,
    this.subtitle,
    this.icon,
    this.errorMessage,
    this.onDismissError,
    this.submitLabel = 'Guardar',
    this.submitIcon,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onDismissError;
  final String submitLabel;
  final IconData? submitIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      insetPadding: const EdgeInsets.all(LavaderoSpacing.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LavaderoSizes.dialogWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LavaderoSpacing.lg),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (icon != null) ...[
                      IconBadge(icon: icon!),
                      const SizedBox(width: LavaderoSpacing.md),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: theme.textTheme.titleLarge),
                          if (subtitle != null) ...[
                            const SizedBox(height: LavaderoSpacing.xxs),
                            Text(
                              subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Cerrar',
                      icon: const Icon(
                        Icons.close_rounded,
                        size: LavaderoSizes.iconMd,
                      ),
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: LavaderoSpacing.lg),
                for (var i = 0; i < fields.length; i++) ...[
                  if (i > 0) const SizedBox(height: LavaderoSpacing.md),
                  fields[i],
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: LavaderoSpacing.md),
                  ErrorBanner(
                    message: errorMessage!,
                    onDismiss: onDismissError,
                  ),
                ],
                const SizedBox(height: LavaderoSpacing.lg),
                // Wrap y no Row: con una etiqueta larga o en un teléfono angosto,
                // el botón principal baja de línea en vez de desbordarse.
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: LavaderoSpacing.sm,
                  runSpacing: LavaderoSpacing.sm,
                  children: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    LoadingButton(
                      onPressed: onSubmit,
                      isLoading: isLoading,
                      icon: submitIcon,
                      child: Text(submitLabel),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
