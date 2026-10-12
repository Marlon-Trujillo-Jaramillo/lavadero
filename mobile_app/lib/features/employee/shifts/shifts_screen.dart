import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/agenda_controller.dart';

/// Agenda del día para el empleado: qué carros están reservados/en curso/listos en su sucursal.
/// Consume `/api/v1/agenda/reservas` (vista de empleado). Reemplaza el antiguo placeholder
/// "Turnos" — la gestión de turnos de personal, si resulta ser un concepto distinto, se separa a
/// futuro (ver docs/specs/002-agenda-reservas.md).
class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agendaControllerProvider);
    final controller = ref.read(agendaControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Agenda de hoy')),
      body: RefreshIndicator(
        onRefresh: controller.cargar,
        child: Padding(
          padding: const EdgeInsets.all(LavaderoSpacing.md),
          child: _buildBody(context, state, controller),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AgendaState state, AgendaController controller) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return ListView(children: [ErrorBanner(message: state.errorMessage!)]);
    }
    if (state.reservas.isEmpty) {
      return ListView(
        children: const [
          EmptyState(icon: Icons.calendar_month_outlined, title: 'No hay reservas para hoy'),
        ],
      );
    }
    return ListView.separated(
      itemCount: state.reservas.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) => _ReservaTile(reserva: state.reservas[index], controller: controller),
    );
  }
}

class _ReservaTile extends StatelessWidget {
  const _ReservaTile({required this.reserva, required this.controller});

  final Reserva reserva;
  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    final hora = reserva.fechaHoraInicio.toLocal();
    final horaTexto = '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

    return ListTile(
      leading: _EstadoIcon(estado: reserva.estado),
      title: Text(horaTexto),
      subtitle: Text('${reserva.duracionEstimadaMinutos} min · \$${reserva.precio.toStringAsFixed(0)}'),
      trailing: _AccionPorEstado(reserva: reserva, controller: controller),
    );
  }
}

class _EstadoIcon extends StatelessWidget {
  const _EstadoIcon({required this.estado});

  final ReservaEstado estado;

  @override
  Widget build(BuildContext context) {
    return switch (estado) {
      ReservaEstado.pendiente => const Icon(Icons.schedule_outlined),
      ReservaEstado.enProgreso => Icon(Icons.local_car_wash, color: Theme.of(context).colorScheme.primary),
      ReservaEstado.completada => Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
      ReservaEstado.cancelada => const Icon(Icons.cancel_outlined),
    };
  }
}

class _AccionPorEstado extends StatelessWidget {
  const _AccionPorEstado({required this.reserva, required this.controller});

  final Reserva reserva;
  final AgendaController controller;

  @override
  Widget build(BuildContext context) {
    return switch (reserva.estado) {
      ReservaEstado.pendiente => TextButton(
          onPressed: () => controller.iniciar(reserva.id),
          child: const Text('Iniciar'),
        ),
      ReservaEstado.enProgreso => TextButton(
          onPressed: () => controller.completar(reserva.id),
          child: const Text('Completar'),
        ),
      ReservaEstado.completada || ReservaEstado.cancelada => const SizedBox.shrink(),
    };
  }
}
