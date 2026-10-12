import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/agenda_controller.dart';

String _formatearFecha(DateTime fecha) {
  String dosDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dosDigitos(fecha.day)}/${dosDigitos(fecha.month)}/${fecha.year}';
}

String _formatearHora(DateTime fechaHora) {
  String dosDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dosDigitos(fechaHora.hour)}:${dosDigitos(fechaHora.minute)}';
}

(String, Color) _estadoInfo(BuildContext context, ReservaEstado estado) {
  final scheme = Theme.of(context).colorScheme;
  return switch (estado) {
    ReservaEstado.pendiente => ('Pendiente', LavaderoColors.warning),
    ReservaEstado.enProgreso => ('En progreso', scheme.primary),
    ReservaEstado.completada => ('Completada', LavaderoColors.success),
    ReservaEstado.cancelada => ('Cancelada', scheme.outline),
  };
}

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

    return Padding(
      padding: const EdgeInsets.all(LavaderoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Filtros(state: state, controller: controller),
          const SizedBox(height: LavaderoSpacing.md),
          if (state.errorMessage != null) ...[
            ErrorBanner(message: state.errorMessage!),
            const SizedBox(height: LavaderoSpacing.md),
          ],
          Expanded(child: _Listado(state: state, controller: controller)),
        ],
      ),
    );
  }
}

class _Filtros extends StatelessWidget {
  const _Filtros({required this.state, required this.controller});

  final AgendaState state;
  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LavaderoSpacing.md,
          vertical: LavaderoSpacing.sm,
        ),
        child: Wrap(
          spacing: LavaderoSpacing.md,
          runSpacing: LavaderoSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                initialValue: state.sucursalSeleccionadaId,
                decoration: const InputDecoration(labelText: 'Sucursal'),
                items: [
                  for (final sucursal in state.sucursales)
                    DropdownMenuItem(value: sucursal.id, child: Text(sucursal.nombre)),
                ],
                onChanged: state.sucursales.isEmpty
                    ? null
                    : (id) {
                        if (id != null) controller.seleccionarSucursal(id);
                      },
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Día anterior',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () =>
                      controller.irADia(state.fecha.subtract(const Duration(days: 1))),
                ),
                Text(_formatearFecha(state.fecha), style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  tooltip: 'Día siguiente',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => controller.irADia(state.fecha.add(const Duration(days: 1))),
                ),
                TextButton(onPressed: controller.irAHoy, child: const Text('Hoy')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Listado extends StatelessWidget {
  const _Listado({required this.state, required this.controller});

  final AgendaState state;
  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.reservas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.sucursales.isEmpty) {
      return const EmptyState(
        icon: Icons.store_mall_directory_outlined,
        title: 'Todavía no hay sucursales',
        message: 'Creá una sucursal para poder ver su agenda.',
      );
    }

    if (state.reservas.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No hay reservas para este día',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.recargar,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: state.reservas.length,
        separatorBuilder: (context, index) => const SizedBox(height: LavaderoSpacing.sm),
        itemBuilder: (context, index) {
          final reserva = state.reservas[index];
          return _ReservaCard(
            reserva: reserva,
            cambiandoEstado: state.cambiandoEstadoId == reserva.id,
            controller: controller,
          );
        },
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  const _ReservaCard({
    required this.reserva,
    required this.cambiandoEstado,
    required this.controller,
  });

  final Reserva reserva;
  final bool cambiandoEstado;
  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _estadoInfo(context, reserva.estado);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.14),
          child: Text(_formatearHora(reserva.fechaHoraInicio.toLocal()).substring(0, 2)),
        ),
        title: Text(_formatearHora(reserva.fechaHoraInicio.toLocal())),
        subtitle: Text(
          '${reserva.duracionEstimadaMinutos} min · \$${reserva.precio.toStringAsFixed(0)} ${reserva.moneda}',
        ),
        trailing: cambiandoEstado
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(label: label, color: color),
                  const SizedBox(width: LavaderoSpacing.sm),
                  ..._acciones(context),
                ],
              ),
      ),
    );
  }

  List<Widget> _acciones(BuildContext context) {
    return switch (reserva.estado) {
      ReservaEstado.pendiente => [
          TextButton(onPressed: () => controller.iniciar(reserva.id), child: const Text('Iniciar')),
          IconButton(
            tooltip: 'Cancelar',
            icon: const Icon(Icons.close),
            onPressed: () => controller.cancelar(reserva.id),
          ),
        ],
      ReservaEstado.enProgreso => [
          TextButton(
            onPressed: () => controller.completar(reserva.id),
            child: const Text('Completar'),
          ),
        ],
      ReservaEstado.completada || ReservaEstado.cancelada => const [],
    };
  }
}
