import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../auth/application/auth_controller.dart';
import '../shifts/application/agenda_controller.dart';
import 'application/incidents_controller.dart';

/// Incidencias reportadas por el empleado — reemplaza el placeholder "Próximamente". Ver
/// docs/specs/006-checklist-incidencias.md.
class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Incidencias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(IncidentsState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return ErrorBanner(message: state.errorMessage!);
    }
    if (state.incidencias.isEmpty) {
      return const EmptyState(
        icon: Icons.report_problem_outlined,
        title: 'No has reportado incidencias',
      );
    }
    return ListView.separated(
      itemCount: state.incidencias.length,
      separatorBuilder: (context, index) => const SizedBox(height: LavaderoSpacing.sm),
      itemBuilder: (context, index) {
        final incidencia = state.incidencias[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.report_problem_outlined),
            title: Text(incidencia.categoria.label),
            subtitle: Text(incidencia.descripcion),
          ),
        );
      },
    );
  }

  void _abrirFormulario(BuildContext context) {
    showDialog<void>(context: context, builder: (context) => const _IncidenciaFormDialog());
  }
}

class _IncidenciaFormDialog extends ConsumerStatefulWidget {
  const _IncidenciaFormDialog();

  @override
  ConsumerState<_IncidenciaFormDialog> createState() => _IncidenciaFormDialogState();
}

class _IncidenciaFormDialogState extends ConsumerState<_IncidenciaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  IncidenciaCategoria _categoria = IncidenciaCategoria.otro;
  String? _reservaId;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated || authState.user.sucursalId == null) {
      setState(() => _errorMessage = 'Tu usuario no tiene una sucursal asignada.');
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(incidentsControllerProvider.notifier).crear(
            sucursalId: authState.user.sucursalId!,
            reservaId: _reservaId,
            categoria: _categoria,
            descripcion: _descripcionController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reservas = ref.watch(agendaControllerProvider).reservas;

    return AlertDialog(
      title: const Text('Reportar incidencia'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<IncidenciaCategoria>(
                initialValue: _categoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: [
                  for (final categoria in IncidenciaCategoria.values)
                    DropdownMenuItem(value: categoria, child: Text(categoria.label)),
                ],
                onChanged: (categoria) => setState(() => _categoria = categoria ?? _categoria),
              ),
              if (reservas.isNotEmpty) ...[
                const SizedBox(height: LavaderoSpacing.sm),
                DropdownButtonFormField<String?>(
                  initialValue: _reservaId,
                  decoration: const InputDecoration(labelText: 'Reserva relacionada (opcional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Ninguna')),
                    for (final reserva in reservas)
                      DropdownMenuItem(value: reserva.id, child: Text(_horaDe(reserva))),
                  ],
                  onChanged: (reservaId) => setState(() => _reservaId = reservaId),
                ),
              ],
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _descripcionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Describe qué pasó' : null,
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: LavaderoSpacing.md),
                ErrorBanner(message: _errorMessage!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        LoadingButton(onPressed: _guardar, isLoading: _isLoading, child: const Text('Reportar')),
      ],
    );
  }

  String _horaDe(Reserva reserva) {
    final hora = reserva.fechaHoraInicio.toLocal();
    String dosDigitos(int n) => n.toString().padLeft(2, '0');
    return '${dosDigitos(hora.hour)}:${dosDigitos(hora.minute)}';
  }
}
