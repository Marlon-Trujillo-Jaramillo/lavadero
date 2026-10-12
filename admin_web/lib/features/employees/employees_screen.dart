import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/employees_controller.dart';

/// Staff (rol EMPLEADO) del tenant actual. Antes de esto la única forma de tener un empleado en
/// el sistema era una fila insertada a mano en la base de datos — reemplaza el placeholder
/// "coming soon". Sin sistema de notificaciones todavía: el admin fija la contraseña inicial y se
/// la comunica al empleado fuera de banda (ver `CrearEmpleadoUseCase`, backend).
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(employeesControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.person_add_alt_outlined),
        label: const Text('Nuevo empleado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: LavaderoSpacing.md),
                child: ErrorBanner(message: state.errorMessage!),
              ),
            if (state.isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (state.empleados.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.people_outline,
                  title: 'Todavía no hay empleados',
                  message: 'Da de alta al primer miembro del staff.',
                  actionLabel: 'Nuevo empleado',
                  onAction: () => _abrirFormulario(context),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: state.empleados.length,
                  separatorBuilder: (context, index) => const SizedBox(height: LavaderoSpacing.sm),
                  itemBuilder: (context, index) {
                    final empleado = state.empleados[index];
                    Sucursal? sucursal;
                    for (final s in state.sucursales) {
                      if (s.id == empleado.sucursalId) {
                        sucursal = s;
                        break;
                      }
                    }
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                        title: Text(empleado.nombre),
                        subtitle: Text(
                          sucursal == null ? empleado.email : '${empleado.email} · ${sucursal.nombre}',
                        ),
                        trailing: StatusBadge(
                          label: empleado.estado == 'ACTIVO' ? 'Activo' : 'Bloqueado',
                          color: empleado.estado == 'ACTIVO'
                              ? LavaderoColors.success
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _abrirFormulario(BuildContext context) {
    showDialog<void>(context: context, builder: (context) => const _EmpleadoFormDialog());
  }
}

class _EmpleadoFormDialog extends ConsumerStatefulWidget {
  const _EmpleadoFormDialog();

  @override
  ConsumerState<_EmpleadoFormDialog> createState() => _EmpleadoFormDialogState();
}

class _EmpleadoFormDialogState extends ConsumerState<_EmpleadoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _sucursalId;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _nombreController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(employeesControllerProvider.notifier).crear(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nombre: _nombreController.text.trim(),
            sucursalId: _sucursalId,
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
    final sucursales = ref.watch(employeesControllerProvider).sucursales;

    return AlertDialog(
      title: const Text('Nuevo empleado'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Ingresa un email válido'
                    : null,
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña inicial',
                  helperText: 'Se la comunicás al empleado vos mismo — todavía no hay envío automático.',
                  helperMaxLines: 2,
                ),
                obscureText: true,
                validator: (value) =>
                    (value == null || value.length < 8) ? 'Mínimo 8 caracteres' : null,
              ),
              if (sucursales.isNotEmpty) ...[
                const SizedBox(height: LavaderoSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _sucursalId,
                  decoration: const InputDecoration(labelText: 'Sucursal (opcional)'),
                  items: [
                    for (final sucursal in sucursales)
                      DropdownMenuItem(value: sucursal.id, child: Text(sucursal.nombre)),
                  ],
                  onChanged: (id) => setState(() => _sucursalId = id),
                ),
              ],
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
        LoadingButton(onPressed: _guardar, isLoading: _isLoading, child: const Text('Guardar')),
      ],
    );
  }
}
