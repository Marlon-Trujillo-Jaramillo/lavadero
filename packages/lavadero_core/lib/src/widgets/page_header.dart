import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Encabezado de página: titular grande, descripción opcional y, a la
/// derecha, un [trailing] que siempre queda en línea (p. ej. el botón de
/// perfil de la app móvil) y/o [actions] que en angosto bajan debajo del
/// título. Va como primer hijo del scroll de la pantalla en vez de un
/// `AppBar` plano (título "large" que se desplaza con el contenido).
///
/// En `admin_web` el shell ya pinta el título de cada sección, así que allí
/// no se usa para repetirlo.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.description,
    this.actions = const [],
    this.trailing,
  });

  final String title;
  final String? description;
  final List<Widget> actions;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heading = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.headlineMedium),
              if (description != null) ...[
                const SizedBox(height: LavaderoSpacing.xs),
                Text(
                  description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: LavaderoSpacing.md),
          trailing!,
        ],
      ],
    );
    final actionRow = Wrap(
      spacing: LavaderoSpacing.sm,
      runSpacing: LavaderoSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: actions,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: LavaderoSpacing.lg),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (actions.isEmpty) return heading;
          if (constraints.maxWidth < LavaderoBreakpoints.compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                heading,
                const SizedBox(height: LavaderoSpacing.md),
                actionRow,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: heading),
              const SizedBox(width: LavaderoSpacing.md),
              actionRow,
            ],
          );
        },
      ),
    );
  }
}
