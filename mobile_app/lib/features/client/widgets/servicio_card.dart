import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// Tarjeta de servicio para la grilla del inicio: ícono, nombre, duración y
/// precio. Tocarla lleva a reservar ese servicio.
class ServicioCard extends StatelessWidget {
  const ServicioCard({super.key, required this.servicio, required this.onTap});

  final ServiceItem servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      button: true,
      label: 'Reservar ${servicio.nombre}',
      child: LavaderoCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon: servicio.icono, color: servicio.colorAcento),
            const SizedBox(height: LavaderoSpacing.md),
            Text(
              servicio.nombre,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: LavaderoSpacing.xxs),
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: LavaderoSizes.iconSm - LavaderoSpacing.xxs,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(width: LavaderoSpacing.xs),
                Text(
                  servicio.duracionTexto,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const SizedBox(height: LavaderoSpacing.sm),
            Text(
              servicio.precioTexto,
              style: theme.textTheme.titleMedium?.copyWith(
                color: scheme.primary,
                fontFeatures: LavaderoTypography.tabular,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
