import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';


/// Tarjeta héroe del inicio con la reserva activa más cercana: servicio,
/// cuándo, y una barra que se llena a medida que se acerca la hora (o que
/// avanza el lavado, si ya está en curso).
class ProximaReservaHero extends StatelessWidget {
  const ProximaReservaHero({
    super.key,
    required this.reserva,
    required this.servicio,
    required this.ahora,
    this.onTap,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final DateTime ahora;
  final VoidCallback? onTap;

  /// Ventana de la cuenta regresiva: a más de un día, la barra arranca casi
  /// vacía.
  static const _ventana = Duration(hours: 24);

  bool get _enCurso =>
      reserva.estado == ReservaEstado.enProgreso ||
      !reserva.fechaHoraInicio.isAfter(ahora);

  double get _progreso {
    if (_enCurso) {
      final total = reserva.fechaHoraFin.difference(reserva.fechaHoraInicio);
      if (total.inSeconds <= 0) return 1;
      final hecho = total - _quedan;
      return (hecho.inSeconds / total.inSeconds).clamp(0.05, 1.0);
    }
    final falta = reserva.fechaHoraInicio.difference(ahora);
    return (1 - falta.inSeconds / _ventana.inSeconds).clamp(0.05, 1.0);
  }

  /// Si el lavado arrancó antes de su hora agendada, lo que queda nunca
  /// puede superar la duración del servicio.
  Duration get _quedan {
    final total = reserva.fechaHoraFin.difference(reserva.fechaHoraInicio);
    final hastaFin = reserva.fechaHoraFin.difference(ahora);
    return hastaFin > total ? total : hastaFin;
  }

  String get _faltaTexto {
    if (_enCurso) {
      final quedan = _quedan;
      return quedan.inMinutes > 0
          ? 'Quedan ${Formato.duracion(quedan)}'
          : 'Por terminar';
    }
    final falta = reserva.fechaHoraInicio.difference(ahora);
    if (falta.inMinutes < 60) return 'En ${math.max(1, falta.inMinutes)} min';
    if (falta < _ventana) return 'En ${Formato.duracion(falta)}';
    return Formato.diaRelativo(reserva.fechaHoraInicio.toLocal(), ahora: ahora);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inicio = reserva.fechaHoraInicio.toLocal();
    final secundario = LavaderoColors.onBrandMuted;
    return Semantics(
      button: onTap != null,
      label: 'Próxima reserva',
      child: LavaderoCard(
        onTap: onTap,
        gradient: LavaderoGradients.deep,
        padding: const EdgeInsets.all(LavaderoSpacing.lg - LavaderoSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GlassPill(
                  label: _enCurso ? 'Lavando ahora' : 'Próxima reserva',
                  icon: _enCurso
                      ? Icons.local_car_wash_rounded
                      : Icons.event_available_rounded,
                ),
                const Spacer(),
                Icon(Icons.arrow_forward_rounded, color: secundario),
              ],
            ),
            const SizedBox(height: LavaderoSpacing.md),
            Text(
              servicio?.nombre ?? 'Tu lavado',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                color: LavaderoColors.white,
              ),
            ),
            const SizedBox(height: LavaderoSpacing.xxs),
            Text(
              '${Formato.diaRelativo(inicio, ahora: ahora)} · '
              '${Formato.hora(inicio)} · ${reserva.duracionEstimadaMinutos} min',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secundario,
                fontFeatures: LavaderoTypography.tabular,
              ),
            ),
            const SizedBox(height: LavaderoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progreso),
                    duration: LavaderoMotion.slow * 2,
                    curve: LavaderoMotion.emphasized,
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: LavaderoSpacing.sm,
                      borderRadius: BorderRadius.circular(LavaderoRadii.full),
                      backgroundColor: LavaderoColors.white.withValues(
                        alpha: 0.2,
                      ),
                      color: LavaderoColors.white,
                    ),
                  ),
                ),
                const SizedBox(width: LavaderoSpacing.md),
                Text(
                  _faltaTexto,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: LavaderoColors.white,
                    fontFeatures: LavaderoTypography.tabular,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Héroe alternativo cuando no hay reservas activas: invita a reservar.
class ReservarCtaHero extends StatelessWidget {
  const ReservarCtaHero({super.key, required this.onReservar});

  final VoidCallback onReservar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LavaderoCard(
      gradient: LavaderoGradients.deep,
      padding: const EdgeInsets.all(LavaderoSpacing.lg - LavaderoSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassPill(
            label: 'Sin reservas activas',
            icon: Icons.bolt_rounded,
          ),
          const SizedBox(height: LavaderoSpacing.md),
          Text(
            'Agenda tu próximo lavado',
            style: theme.textTheme.titleLarge?.copyWith(
              color: LavaderoColors.white,
            ),
          ),
          const SizedBox(height: LavaderoSpacing.xxs),
          Text(
            'Elige servicio, día y hora en segundos.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: LavaderoColors.onBrandMuted,
            ),
          ),
          const SizedBox(height: LavaderoSpacing.md),
          FilledButton.icon(
            onPressed: onReservar,
            style: FilledButton.styleFrom(
              backgroundColor: LavaderoColors.white,
              foregroundColor: LavaderoColors.ocean,
              minimumSize: const Size(0, LavaderoSizes.minTapTarget),
            ),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Reservar ahora'),
          ),
        ],
      ),
    );
  }
}
