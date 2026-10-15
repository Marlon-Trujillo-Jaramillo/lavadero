import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import 'application/agenda_controller.dart';

/// Agenda del día para el dueño/administrador del tenant: ver y gestionar las reservas concretas
/// de una sucursal (no solo el resumen agregado de `DashboardScreen`/`ReportsScreen`). Consume
/// `GET /api/v1/agenda/reservas` + las acciones iniciar/completar/cancelar, igual que la agenda de
/// empleado en `mobile_app`, pero con selector de sucursal (un admin puede tener varias).
class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agendaControllerProvider);
    final controller = ref.read(agendaControllerProvider.notifier);
    final sinSucursales = state.sucursales.isEmpty;

    return AdminPage(
      toolbar: PageToolbar(
        leading: _NavegadorFecha(
          fecha: state.fecha,
          onCambiar: controller.irADia,
          onHoy: controller.irAHoy,
        ),
        actions: [
          if (!sinSucursales)
            _SelectorSucursal(
              sucursales: state.sucursales,
              seleccionadaId: state.sucursalSeleccionadaId,
              onCambiar: controller.seleccionarSucursal,
            ),
          IconButton(
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: state.isLoading ? null : controller.recargar,
          ),
        ],
      ),
      banner: state.errorMessage != null && !sinSucursales
          ? ErrorBanner(
              message: state.errorMessage!,
              onRetry: controller.recargar,
              onDismiss: controller.descartarError,
            )
          : null,
      body: _Cuerpo(state: state, controller: controller),
    );
  }
}

class _Cuerpo extends StatelessWidget {
  const _Cuerpo({required this.state, required this.controller});

  final AgendaState state;
  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.reservas.isEmpty) {
      return const SkeletonList(itemCount: 5, padding: EdgeInsets.zero);
    }

    if (state.sucursales.isEmpty) {
      if (state.errorMessage != null) {
        return Align(
          alignment: Alignment.topCenter,
          child: ErrorBanner(
            message: state.errorMessage!,
            onRetry: controller.recargar,
          ),
        );
      }
      return const EmptyState(
        icon: Icons.storefront_outlined,
        title: 'Todavía no hay sucursales',
        message:
            'Crea tu primera sucursal en la sección Sucursales para empezar '
            'a recibir reservas y ver su agenda aquí.',
      );
    }

    if (state.reservas.isEmpty) {
      final cuando = switch (Formato.diaRelativo(state.fecha)) {
        final dia && ('Hoy' || 'Mañana' || 'Ayer') => dia.toLowerCase(),
        final dia => 'el $dia',
      };
      return EmptyState(
        icon: Icons.event_available_outlined,
        title: 'Agenda libre',
        message:
            'No hay reservas para $cuando '
            'en esta sucursal. Las reservas que hagan tus clientes aparecerán aquí.',
      );
    }

    final grupos = _agruparPorHora(state.reservas);
    final hayAccionEnCurso = state.cambiandoEstadoId != null;
    var indice = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResumenDelDia(state: state),
        const SizedBox(height: LavaderoSpacing.md),
        if (state.isLoading)
          const LinearProgressIndicator(minHeight: LavaderoSpacing.xxs)
        else
          const SizedBox(height: LavaderoSpacing.xxs),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(
              top: LavaderoSpacing.sm,
              bottom: LavaderoSpacing.xl,
            ),
            children: [
              for (final grupo in grupos.entries) ...[
                _EncabezadoHora(hora: grupo.key, cantidad: grupo.value.length),
                for (final reserva in grupo.value)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LavaderoSpacing.sm),
                    child: FadeSlideIn(
                      index: indice++,
                      child: _ReservaFila(
                        reserva: reserva,
                        nombreServicio:
                            state.servicios[reserva.servicioId]?.nombre,
                        cambiandoEstado: state.cambiandoEstadoId == reserva.id,
                        accionesHabilitadas: !hayAccionEnCurso,
                        controller: controller,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Agrupa por hora de inicio (local), conservando el orden cronológico.
  Map<int, List<Reserva>> _agruparPorHora(List<Reserva> reservas) {
    final grupos = <int, List<Reserva>>{};
    for (final reserva in reservas) {
      grupos
          .putIfAbsent(reserva.fechaHoraInicio.toLocal().hour, () => [])
          .add(reserva);
    }
    return grupos;
  }
}

/// Fecha con flechas día anterior/siguiente, selector de calendario al tocar la fecha y atajo
/// "Hoy" cuando se está mirando otro día.
class _NavegadorFecha extends StatelessWidget {
  const _NavegadorFecha({
    required this.fecha,
    required this.onCambiar,
    required this.onHoy,
  });

  final DateTime fecha;
  final ValueChanged<DateTime> onCambiar;
  final VoidCallback onHoy;

  Future<void> _elegirFecha(BuildContext context) async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: fecha,
      firstDate: DateTime(hoy.year - 1),
      lastDate: DateTime(hoy.year + 1, 12, 31),
    );
    if (elegida != null) onCambiar(elegida);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final relativo = Formato.diaRelativo(fecha);
    final esHoy = relativo == 'Hoy';
    final esRelativo = relativo != Formato.fechaCorta(fecha);
    return Wrap(
      spacing: LavaderoSpacing.sm,
      runSpacing: LavaderoSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(LavaderoRadii.md),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Día anterior',
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () =>
                    onCambiar(fecha.subtract(const Duration(days: 1))),
              ),
              Tooltip(
                message: 'Elegir fecha',
                child: InkWell(
                  borderRadius: BorderRadius.circular(LavaderoRadii.sm),
                  onTap: () => _elegirFecha(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LavaderoSpacing.sm,
                      vertical: LavaderoSpacing.xs,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: LavaderoSizes.iconSm,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: LavaderoSpacing.sm),
                        Text(
                          esRelativo ? relativo : Formato.fechaCorta(fecha),
                          style: theme.textTheme.titleSmall,
                        ),
                        if (esRelativo) ...[
                          const SizedBox(
                            width: LavaderoSpacing.xs + LavaderoSpacing.xxs,
                          ),
                          Text(
                            Formato.fechaCorta(fecha),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Día siguiente',
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: () => onCambiar(fecha.add(const Duration(days: 1))),
              ),
            ],
          ),
        ),
        if (!esHoy) TextButton(onPressed: onHoy, child: const Text('Ir a hoy')),
      ],
    );
  }
}

class _SelectorSucursal extends StatelessWidget {
  const _SelectorSucursal({
    required this.sucursales,
    required this.seleccionadaId,
    required this.onCambiar,
  });

  final List<Sucursal> sucursales;
  final String? seleccionadaId;
  final ValueChanged<String> onCambiar;

  static const double _ancho = 260;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ancho,
      child: DropdownButtonFormField<String>(
        // La key fuerza a reconstruir el campo si cambia la selección desde el controller.
        key: ValueKey(seleccionadaId),
        initialValue: seleccionadaId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Sucursal',
          prefixIcon: Icon(Icons.storefront_outlined),
          isDense: true,
        ),
        items: [
          for (final sucursal in sucursales)
            DropdownMenuItem(
              value: sucursal.id,
              child: Text(sucursal.nombre, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (id) {
          if (id != null) onCambiar(id);
        },
      ),
    );
  }
}

/// Conteo por estado + ingresos ya cobrados (reservas completadas) del día.
class _ResumenDelDia extends StatelessWidget {
  const _ResumenDelDia({required this.state});

  final AgendaState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completadas = state.reservas.where(
      (r) => r.estado == ReservaEstado.completada,
    );
    final ingresos = completadas.fold<double>(
      0,
      (total, r) => total + r.precio,
    );
    final moneda = state.reservas.first.moneda;
    return Wrap(
      spacing: LavaderoSpacing.sm,
      runSpacing: LavaderoSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final estado in const [
          ReservaEstado.pendiente,
          ReservaEstado.enProgreso,
          ReservaEstado.completada,
        ])
          _ContadorEstado(estado: estado, cantidad: state.contar(estado)),
        if (state.contar(ReservaEstado.cancelada) > 0)
          _ContadorEstado(
            estado: ReservaEstado.cancelada,
            cantidad: state.contar(ReservaEstado.cancelada),
          ),
        Padding(
          padding: const EdgeInsets.only(left: LavaderoSpacing.sm),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Cobrado  ',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextSpan(
                  text: Formato.moneda(ingresos, moneda),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFeatures: LavaderoTypography.tabular,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ContadorEstado extends StatelessWidget {
  const _ContadorEstado({required this.estado, required this.cantidad});

  final ReservaEstado estado;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = estado.colorDe(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.smd,
        vertical: LavaderoSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LavaderoRadii.md),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: LavaderoSpacing.sm,
            height: LavaderoSpacing.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          Text(
            estado.etiqueta,
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          Text(
            '$cantidad',
            style: theme.textTheme.titleSmall?.copyWith(
              fontFeatures: LavaderoTypography.tabular,
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoHora extends StatelessWidget {
  const _EncabezadoHora({required this.hora, required this.cantidad});

  final int hora;
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(
        top: LavaderoSpacing.sm,
        bottom: LavaderoSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            '${hora.toString().padLeft(2, '0')}:00',
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: LavaderoTypography.tabular,
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          Expanded(child: const Divider(height: LavaderoSizes.hairline)),
          const SizedBox(width: LavaderoSpacing.sm),
          Text(
            cantidad == 1 ? '1 reserva' : '$cantidad reservas',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservaFila extends StatelessWidget {
  const _ReservaFila({
    required this.reserva,
    required this.nombreServicio,
    required this.cambiandoEstado,
    required this.accionesHabilitadas,
    required this.controller,
  });

  final Reserva reserva;
  final String? nombreServicio;
  final bool cambiandoEstado;
  final bool accionesHabilitadas;
  final AgendaController controller;

  static const double _anchoHora = 76;
  static const double _anchoCompacto = 640;

  Future<void> _cancelar(BuildContext context) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Cancelar esta reserva?',
      message:
          'El horario de las ${Formato.hora(reserva.fechaHoraInicio.toLocal())} '
          'quedará libre y el cliente verá la reserva como cancelada. '
          'Esta acción no se puede deshacer.',
      confirmLabel: 'Cancelar reserva',
      icon: Icons.event_busy_outlined,
      destructive: true,
    );
    if (confirmado) await controller.cancelar(reserva.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = reserva.estado.colorDe(context);
    final inicio = reserva.fechaHoraInicio.toLocal();
    final fin = reserva.fechaHoraFin.toLocal();
    final cancelada = reserva.estado == ReservaEstado.cancelada;

    final hora = Container(
      width: _anchoHora,
      padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(LavaderoRadii.md),
      ),
      child: Column(
        children: [
          Text(
            Formato.hora(inicio),
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontFeatures: LavaderoTypography.tabular,
            ),
          ),
          Text(
            Formato.hora(fin),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontFeatures: LavaderoTypography.tabular,
            ),
          ),
        ],
      ),
    );

    final detalle = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombreServicio ?? 'Servicio',
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            decoration: cancelada ? TextDecoration.lineThrough : null,
          ),
        ),
        const SizedBox(height: LavaderoSpacing.xs + LavaderoSpacing.xxs),
        Wrap(
          spacing: LavaderoSpacing.xs + LavaderoSpacing.xxs,
          runSpacing: LavaderoSpacing.xs,
          children: [
            MetaPill(
              icon: Icons.schedule_rounded,
              label: Formato.duracion(
                Duration(minutes: reserva.duracionEstimadaMinutos),
              ),
            ),
            MetaPill(
              icon: Icons.payments_outlined,
              label: Formato.moneda(reserva.precio, reserva.moneda),
            ),
          ],
        ),
      ],
    );

    final estadoYAcciones = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ReservaEstadoBadge(estado: reserva.estado),
        ..._acciones(context),
      ],
    );

    return LavaderoCard(
      padding: const EdgeInsets.all(LavaderoSpacing.smd),
      child: Opacity(
        opacity: cancelada ? 0.6 : 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < _anchoCompacto) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  hora,
                  const SizedBox(width: LavaderoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        detalle,
                        const SizedBox(height: LavaderoSpacing.sm),
                        estadoYAcciones,
                      ],
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                hora,
                const SizedBox(width: LavaderoSpacing.md),
                Expanded(child: detalle),
                const SizedBox(width: LavaderoSpacing.md),
                estadoYAcciones,
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _acciones(BuildContext context) {
    if (cambiandoEstado) {
      return const [
        SizedBox(width: LavaderoSpacing.md),
        InlineSpinner(),
        SizedBox(width: LavaderoSpacing.sm),
      ];
    }
    final habilitado = accionesHabilitadas;
    return switch (reserva.estado) {
      ReservaEstado.pendiente => [
        const SizedBox(width: LavaderoSpacing.smd),
        FilledButton.tonalIcon(
          onPressed: habilitado ? () => controller.iniciar(reserva.id) : null,
          icon: const Icon(
            Icons.play_arrow_rounded,
            size: LavaderoSizes.iconMd,
          ),
          label: const Text('Iniciar'),
        ),
        const SizedBox(width: LavaderoSpacing.xs),
        IconButton(
          tooltip: 'Cancelar reserva',
          color: Theme.of(context).colorScheme.error,
          icon: const Icon(Icons.close_rounded),
          onPressed: habilitado ? () => _cancelar(context) : null,
        ),
      ],
      ReservaEstado.enProgreso => [
        const SizedBox(width: LavaderoSpacing.smd),
        FilledButton.icon(
          onPressed: habilitado ? () => controller.completar(reserva.id) : null,
          icon: const Icon(Icons.check_rounded, size: LavaderoSizes.iconMd),
          label: const Text('Completar'),
        ),
      ],
      ReservaEstado.completada || ReservaEstado.cancelada => const [],
    };
  }
}
