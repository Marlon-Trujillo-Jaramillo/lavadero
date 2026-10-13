import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../client/catalog/application/catalog_controller.dart';
import '../../shared/widgets/profile_menu_button.dart';
import '../shifts/application/agenda_controller.dart';
import 'application/checklist_controller.dart';

/// Checklist de servicio: el empleado elige una reserva de la agenda de hoy
/// y marca las tareas hechas en una hoja con barra de progreso. Reutiliza
/// `agendaControllerProvider` de `shifts` (misma agenda del día) en vez de
/// duplicar esa llamada — ver docs/specs/006-checklist-incidencias.md.
class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenda = ref.watch(agendaControllerProvider);
    final servicios = {
      for (final s in ref.watch(catalogControllerProvider).items) s.id: s,
    };
    final reservas =
        agenda.reservas
            .where((r) => r.estado != ReservaEstado.cancelada)
            .toList()
          ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: ref.read(agendaControllerProvider.notifier).cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LavaderoSpacing.lg,
              LavaderoSpacing.md,
              LavaderoSpacing.lg,
              LavaderoSpacing.xl,
            ),
            children: [
              const PageHeader(
                title: 'Checklist',
                description: 'Elige un lavado y marca cada tarea al terminarla.',
                trailing: ProfileMenuButton(),
              ),
              if (agenda.isLoading)
                const SkeletonList.inline(itemCount: 4)
              else if (agenda.errorMessage != null)
                ErrorBanner(
                  message: agenda.errorMessage!,
                  onRetry: ref.read(agendaControllerProvider.notifier).cargar,
                )
              else if (reservas.isEmpty) ...[
                const SizedBox(height: LavaderoSpacing.xl),
                const EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'No hay reservas para hoy',
                  message:
                      'El checklist aparece aquí cuando haya reservas en tu '
                      'agenda.',
                ),
              ] else
                for (var i = 0; i < reservas.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LavaderoSpacing.sm),
                    child: FadeSlideIn(
                      index: i,
                      child: _ReservaFila(
                        reserva: reservas[i],
                        servicio: servicios[reservas[i].servicioId],
                        onTap: () => _abrirChecklist(
                          context,
                          reservas[i],
                          servicios[reservas[i].servicioId],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _abrirChecklist(
    BuildContext context,
    Reserva reserva,
    ServiceItem? servicio,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) =>
          _ChecklistSheet(reserva: reserva, servicio: servicio),
    );
  }
}

class _ReservaFila extends StatelessWidget {
  const _ReservaFila({
    required this.reserva,
    required this.servicio,
    required this.onTap,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inicio = reserva.fechaHoraInicio.toLocal();
    return LavaderoCard(
      onTap: onTap,
      child: Row(
        children: [
          IconBadge(
            icon: servicio?.icono ?? Icons.local_car_wash_rounded,
            color: servicio?.colorAcento ?? scheme.primary,
          ),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  servicio?.nombre ?? 'Reserva',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  '${Formato.hora(inicio)} · '
                  '${Formato.duracion(Duration(minutes: reserva.duracionEstimadaMinutos))}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: LavaderoTypography.tabular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          // Antes se mostraba el valor crudo del backend ("EN_PROGRESO").
          ReservaEstadoBadge(estado: reserva.estado),
          const SizedBox(width: LavaderoSpacing.xs),
          Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _ChecklistSheet extends ConsumerStatefulWidget {
  const _ChecklistSheet({required this.reserva, required this.servicio});

  final Reserva reserva;
  final ServiceItem? servicio;

  @override
  ConsumerState<_ChecklistSheet> createState() => _ChecklistSheetState();
}

class _ChecklistSheetState extends ConsumerState<_ChecklistSheet> {
  /// Tareas con un cambio en vuelo: se muestran ya con el valor nuevo
  /// (optimista) hasta que el backend responde.
  final _pendientes = <String>{};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(checklistControllerProvider.notifier)
          .seleccionarReserva(widget.reserva.id),
    );
  }

  Future<void> _toggle(ChecklistItem item) async {
    if (_pendientes.contains(item.tipo)) return;
    setState(() => _pendientes.add(item.tipo));
    await ref
        .read(checklistControllerProvider.notifier)
        .marcar(item.tipo, !item.completado);
    if (mounted) setState(() => _pendientes.remove(item.tipo));
  }

  bool _hecho(ChecklistItem item) =>
      _pendientes.contains(item.tipo) ? !item.completado : item.completado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final state = ref.watch(checklistControllerProvider);
    // La hoja puede abrirse antes de que `seleccionarReserva` cambie el
    // estado: no mostrar las tareas de otra reserva mientras tanto.
    final propia = state.reservaId == widget.reserva.id;
    final items = propia ? state.items : const <ChecklistItem>[];
    final hechos = items.where(_hecho).length;
    final progreso = items.isEmpty ? 0.0 : hechos / items.length;
    final completo = items.isNotEmpty && hechos == items.length;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            LavaderoSpacing.lg,
            0,
            LavaderoSpacing.lg,
            LavaderoSpacing.lg,
          ),
          children: [
            Text(
              widget.servicio?.nombre ?? 'Checklist',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: LavaderoSpacing.xxs),
            Text(
              '${Formato.hora(widget.reserva.fechaHoraInicio.toLocal())} · '
              '${Formato.duracion(Duration(minutes: widget.reserva.duracionEstimadaMinutos))}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: LavaderoSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    completo
                        ? '¡Todo listo!'
                        : '$hechos de ${items.length} tareas',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: completo ? LavaderoColors.success : null,
                    ),
                  ),
                ),
                Text(
                  '${(progreso * 100).round()}%',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: LavaderoTypography.tabular,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LavaderoSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween(end: progreso),
              duration: LavaderoMotion.slow,
              curve: LavaderoMotion.emphasized,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: LavaderoSpacing.sm,
                borderRadius: BorderRadius.circular(LavaderoRadii.full),
                backgroundColor: scheme.surfaceContainerHighest,
                color: completo ? LavaderoColors.success : scheme.primary,
              ),
            ),
            const SizedBox(height: LavaderoSpacing.lg),
            if (state.errorMessage != null && propia) ...[
              ErrorBanner(message: state.errorMessage!),
              const SizedBox(height: LavaderoSpacing.md),
            ],
            if (!propia || state.isLoading)
              const SkeletonList.inline(itemCount: 4)
            else
              for (final item in items) ...[
                _TareaTile(
                  label: item.label,
                  hecho: _hecho(item),
                  enCurso: _pendientes.contains(item.tipo),
                  onTap: () => _toggle(item),
                ),
                const SizedBox(height: LavaderoSpacing.sm),
              ],
          ],
        ),
      ),
    );
  }
}

/// Fila de tarea con un check circular que se llena y "rebota" al marcarla.
class _TareaTile extends StatelessWidget {
  const _TareaTile({
    required this.label,
    required this.hecho,
    required this.enCurso,
    required this.onTap,
  });

  final String label;
  final bool hecho;
  final bool enCurso;
  final VoidCallback onTap;

  static const double _check = LavaderoSizes.iconLg + LavaderoSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      checked: hecho,
      label: label,
      child: Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(LavaderoRadii.md),
        child: AnimatedContainer(
          duration: LavaderoMotion.normal,
          curve: LavaderoMotion.emphasized,
          padding: const EdgeInsets.all(
            LavaderoSpacing.smd,
          ),
          decoration: BoxDecoration(
            color: hecho
                ? LavaderoColors.success.withValues(alpha: 0.08)
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(LavaderoRadii.md),
            border: Border.all(
              color: hecho
                  ? LavaderoColors.success.withValues(alpha: 0.35)
                  : scheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: LavaderoMotion.normal,
                curve: LavaderoMotion.emphasized,
                width: _check,
                height: _check,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hecho
                      ? LavaderoColors.success
                      : LavaderoColors.transparent,
                  border: Border.all(
                    color: hecho ? LavaderoColors.success : scheme.outline,
                    width: LavaderoSpacing.xxs,
                  ),
                ),
                child: AnimatedScale(
                  scale: hecho ? 1 : 0,
                  duration: LavaderoMotion.normal,
                  curve: Curves.easeOutBack,
                  child: const Icon(
                    Icons.check_rounded,
                    size: LavaderoSizes.iconSm,
                    color: LavaderoColors.white,
                  ),
                ),
              ),
              const SizedBox(width: LavaderoSpacing.smd),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: LavaderoMotion.normal,
                  style: (theme.textTheme.bodyLarge ?? const TextStyle())
                      .copyWith(
                        color: hecho
                            ? scheme.onSurfaceVariant
                            : scheme.onSurface,
                        decoration: hecho
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                  child: Text(label),
                ),
              ),
              if (enCurso)
                const InlineSpinner(size: LavaderoSizes.iconSm),
            ],
          ),
        ),
      ),
    );
  }
}
