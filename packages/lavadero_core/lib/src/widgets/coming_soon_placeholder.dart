import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'fade_slide_in.dart';
import 'glass_pill.dart';
import 'icon_badge.dart';
import 'lavadero_card.dart';
import 'section_header.dart';

/// Lo que traerá una feature aún no implementada (una fila del adelanto).
class ComingSoonFeature {
  const ComingSoonFeature({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}

/// Página "Próximamente" de marca para secciones aún no construidas
/// (inventario, CRM, promociones en el panel; vehículos en la app). En vez
/// de un cartel de obras, adelanta qué traerá la feature para que la sección
/// no se sienta rota. No es funcional a propósito.
///
/// Es el cuerpo scrolleable completo: [header] va arriba (p. ej. el
/// `PageHeader` con el botón de perfil en móvil; en el panel web el shell ya
/// pinta el título, así que se omite).
class ComingSoonPlaceholder extends StatelessWidget {
  const ComingSoonPlaceholder({
    super.key,
    required this.icon,
    required this.headline,
    required this.message,
    this.features = const [],
    this.header,
    this.padding = const EdgeInsets.all(LavaderoSpacing.xl),
  });

  final IconData icon;
  final String headline;
  final String message;
  final List<ComingSoonFeature> features;
  final Widget? header;
  final EdgeInsetsGeometry padding;

  static const double _maxWidth = 720;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: padding,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ?header,
                FadeSlideIn(
                  child: LavaderoCard(
                    gradient: LavaderoGradients.deep,
                    padding: const EdgeInsets.all(LavaderoSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBadge(
                              icon: icon,
                              color: LavaderoColors.white,
                              size: LavaderoSizes.avatarLg,
                            ),
                            const Spacer(),
                            const GlassPill(
                              label: 'Próximamente',
                              icon: Icons.schedule_rounded,
                            ),
                          ],
                        ),
                        const SizedBox(height: LavaderoSpacing.lg),
                        Text(
                          headline,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: LavaderoColors.white,
                          ),
                        ),
                        const SizedBox(height: LavaderoSpacing.sm),
                        Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: LavaderoColors.onBrandMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: LavaderoSpacing.xl),
                  const SectionHeader(title: 'Lo que viene'),
                  for (var i = 0; i < features.length; i++) ...[
                    if (i > 0) const SizedBox(height: LavaderoSpacing.sm),
                    FadeSlideIn(
                      index: i + 1,
                      child: _FilaFeature(feature: features[i]),
                    ),
                  ],
                ],
                const SizedBox(height: LavaderoSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      size: LavaderoSizes.iconSm,
                      color: scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: LavaderoSpacing.xs),
                    Flexible(
                      child: Text(
                        'Te avisaremos cuando esté disponible.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaFeature extends StatelessWidget {
  const _FilaFeature({required this.feature});

  final ComingSoonFeature feature;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LavaderoCard(
      child: Row(
        children: [
          IconBadge(icon: feature.icon),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: LavaderoSpacing.xxs),
                Text(
                  feature.message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
