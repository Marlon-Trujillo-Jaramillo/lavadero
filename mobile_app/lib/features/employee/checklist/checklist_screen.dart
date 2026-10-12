import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shifts/application/agenda_controller.dart';
import 'application/checklist_controller.dart';

/// Checklist de servicio: el empleado elige una reserva de la agenda de hoy y marca las tareas
/// hechas. Reemplaza el placeholder "Próximamente" — ver docs/specs/006-checklist-incidencias.md.
/// Reutiliza `agendaControllerProvider` de `shifts` (misma agenda del día que ya se carga ahí) en
/// vez de duplicar esa llamada.
class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agenda = ref.watch(agendaControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checklist de servicio')),
      body: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: _buildBody(context, agenda),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AgendaState agenda) {
    if (agenda.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (agenda.errorMessage != null) {
      return ErrorBanner(message: agenda.errorMessage!);
    }
    if (agenda.reservas.isEmpty) {
      return const EmptyState(
        icon: Icons.checklist_outlined,
        title: 'No hay reservas para hoy',
        message: 'El checklist aparece acá una vez que haya reservas en tu agenda.',
      );
    }
    return ListView.separated(
      itemCount: agenda.reservas.length,
      separatorBuilder: (context, index) => const SizedBox(height: LavaderoSpacing.sm),
      itemBuilder: (context, index) {
        final reserva = agenda.reservas[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.local_car_wash_outlined),
            title: Text(_formatearHora(reserva.fechaHoraInicio.toLocal())),
            subtitle: Text(reserva.estado.wireValue),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _abrirChecklist(context, reserva),
          ),
        );
      },
    );
  }

  void _abrirChecklist(BuildContext context, Reserva reserva) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ChecklistSheet(reserva: reserva),
    );
  }
}

String _formatearHora(DateTime fechaHora) {
  String dosDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dosDigitos(fechaHora.hour)}:${dosDigitos(fechaHora.minute)}';
}

class _ChecklistSheet extends ConsumerStatefulWidget {
  const _ChecklistSheet({required this.reserva});

  final Reserva reserva;

  @override
  ConsumerState<_ChecklistSheet> createState() => _ChecklistSheetState();
}

class _ChecklistSheetState extends ConsumerState<_ChecklistSheet> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(checklistControllerProvider.notifier).seleccionarReserva(widget.reserva.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checklistControllerProvider);
    final controller = ref.read(checklistControllerProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Checklist — ${_formatearHora(widget.reserva.fechaHoraInicio.toLocal())}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: LavaderoSpacing.sm),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: LavaderoSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final item in state.items)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.label),
                  value: item.completado,
                  onChanged: (completado) => controller.marcar(item.tipo, completado ?? false),
                ),
            if (state.errorMessage != null) ...[
              const SizedBox(height: LavaderoSpacing.sm),
              ErrorBanner(message: state.errorMessage!),
            ],
          ],
        ),
      ),
    );
  }
}
