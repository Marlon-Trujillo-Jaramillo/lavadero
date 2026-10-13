import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../shared/widgets/profile_menu_button.dart';
import '../../client_navigation.dart';
import '../application/my_reservations_controller.dart';
import '../application/reservas_agrupadas.dart';

/// Historial de reservas del cliente autenticado (`GET /agenda/reservas/mias`),
/// agrupado en "Próximas" y "Anteriores", con opción de cancelar mientras
/// siga en estado PENDIENTE (única transición válida — ver `Reserva.java`).
class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  Future<void> _confirmarCancelacion(
    BuildContext context,
    WidgetRef ref,
    Reserva reserva,
    ServiceItem? servicio,
  ) async {
    final inicio = reserva.fechaHoraInicio.toLocal();
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.event_busy_rounded, color: scheme.error),
          title: const Text('¿Cancelar esta reserva?'),
          content: Text(
            '${servicio?.nombre ?? 'Tu lavado'} · '
            '${Formato.diaRelativo(inicio)} a las ${Formato.hora(inicio)}.\n'
            'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Volver'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: scheme.error,
                foregroundColor: scheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sí, cancelar'),
            ),
          ],
        );
      },
    );
    if (confirmado != true) return;
    await ref
        .read(myReservationsControllerProvider.notifier)
        .cancelar(reserva.id);
    if (!context.mounted) return;
    if (ref.read(myReservationsControllerProvider).errorMessage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reserva cancelada')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myReservationsControllerProvider);
    final controller = ref.read(myReservationsControllerProvider.notifier);
    final ahora = DateTime.now();
    final proximas = state.proximas(ahora);
    final anteriores = state.anteriores(ahora);

    Widget tarjeta(Reserva reserva, int index, {required bool historial}) {
      final servicio = state.servicios[reserva.servicioId];
      return Padding(
        padding: const EdgeInsets.only(bottom: LavaderoSpacing.sm),
        child: FadeSlideIn(
          index: index,
          child: _ReservaCard(
            reserva: reserva,
            servicio: servicio,
            historial: historial,
            cancelando: state.cancelandoId == reserva.id,
            onCancelar: reserva.estado == ReservaEstado.pendiente
                ? () => _confirmarCancelacion(context, ref, reserva, servicio)
                : null,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LavaderoSpacing.lg,
              LavaderoSpacing.md,
              LavaderoSpacing.lg,
              LavaderoSpacing.xl,
            ),
            children: [
              PageHeader(
                title: 'Mis reservas',
                description: proximas.isEmpty
                    ? 'Tu historial de lavados'
                    : proximas.length == 1
                    ? 'Tienes 1 reserva activa'
                    : 'Tienes ${proximas.length} reservas activas',
                trailing: const ProfileMenuButton(),
              ),
              if (state.errorMessage != null) ...[
                ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: controller.cargar,
                ),
                const SizedBox(height: LavaderoSpacing.md),
              ],
              if (state.isLoading && state.reservas.isEmpty)
                const SkeletonList.inline(itemCount: 4)
              else if (state.reservas.isEmpty) ...[
                const SizedBox(height: LavaderoSpacing.xl),
                EmptyState(
                  icon: Icons.event_note_outlined,
                  title: 'Todavía no tienes reservas',
                  message: 'Cuando reserves un lavado, lo verás aquí.',
                  actionLabel: 'Reservar un lavado',
                  onAction: () => ref
                      .read(clienteTabProvider.notifier)
                      .ir(ClienteTab.reservar),
                ),
              ] else ...[
                if (proximas.isNotEmpty) ...[
                  const SectionHeader(title: 'Próximas'),
                  for (var i = 0; i < proximas.length; i++)
                    tarjeta(proximas[i], i, historial: false),
                  const SizedBox(height: LavaderoSpacing.lg),
                ],
                if (anteriores.isNotEmpty) ...[
                  const SectionHeader(title: 'Anteriores'),
                  for (var i = 0; i < anteriores.length; i++)
                    tarjeta(
                      anteriores[i],
                      proximas.length + i,
                      historial: true,
                    ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  const _ReservaCard({
    required this.reserva,
    required this.servicio,
    required this.historial,
    required this.cancelando,
    required this.onCancelar,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final bool historial;
  final bool cancelando;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inicio = reserva.fechaHoraInicio.toLocal();
    return AnimatedOpacity(
      duration: LavaderoMotion.normal,
      opacity: cancelando ? 0.6 : 1,
      child: LavaderoCard(
        elevated: !historial,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _FechaBloque(fecha: inicio, apagado: historial),
                const SizedBox(width: LavaderoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        servicio?.nombre ?? 'Servicio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: LavaderoSpacing.xxs),
                      Text(
                        '${Formato.diaRelativo(inicio)} · ${Formato.hora(inicio)}'
                        ' · ${Formato.duracion(Duration(minutes: reserva.duracionEstimadaMinutos))}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: LavaderoTypography.tabular,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: LavaderoSpacing.sm),
                ReservaEstadoBadge(estado: reserva.estado),
              ],
            ),
            const SizedBox(height: LavaderoSpacing.smd),
            Row(
              children: [
                if (servicio != null) ...[
                  Icon(
                    servicio!.icono,
                    size: LavaderoSizes.iconSm,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: LavaderoSpacing.xs),
                ],
                Text(
                  Formato.moneda(reserva.precio, reserva.moneda),
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: historial ? scheme.onSurfaceVariant : scheme.primary,
                    fontFeatures: LavaderoTypography.tabular,
                  ),
                ),
                const Spacer(),
                if (onCancelar != null)
                  TextButton.icon(
                    onPressed: cancelando ? null : onCancelar,
                    style: TextButton.styleFrom(
                      foregroundColor: scheme.error,
                      minimumSize: const Size(0, LavaderoSizes.minTapTarget),
                    ),
                    icon: cancelando
                        ? InlineSpinner(
 size: LavaderoSizes.iconSm,
 color: scheme.error,
 )
                        : const Icon(
                            Icons.close_rounded,
                            size: LavaderoSizes.iconMd,
                          ),
                    label: Text(cancelando ? 'Cancelando…' : 'Cancelar'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bloque de calendario: día del mes grande + mes abreviado.
class _FechaBloque extends StatelessWidget {
  const _FechaBloque({required this.fecha, required this.apagado});

  final DateTime fecha;
  final bool apagado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fondo = apagado
        ? scheme.surfaceContainerHighest
        : scheme.primaryContainer;
    final texto = apagado ? scheme.onSurfaceVariant : scheme.onPrimaryContainer;
    return Container(
      width: LavaderoSizes.avatarLg,
      padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.sm),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(LavaderoRadii.md),
      ),
      child: Column(
        children: [
          Text(
            '${fecha.day}',
            style: theme.textTheme.titleLarge?.copyWith(
              color: texto,
              height: 1,
              fontFeatures: LavaderoTypography.tabular,
            ),
          ),
          const SizedBox(height: LavaderoSpacing.xxs),
          Text(
            Formato.fechaCorta(fecha).split(' ').last,
            style: theme.textTheme.labelSmall?.copyWith(color: texto),
          ),
        ],
      ),
    );
  }
}
