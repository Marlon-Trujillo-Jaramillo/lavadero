import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/branches_controller.dart';

/// Sucursales del tenant actual. Antes de esto la única forma de que un tenant tuviera más de una
/// sucursal era una inserción manual en la base de datos — reemplaza el placeholder "coming soon".
class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchesControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nueva sucursal'),
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
            else if (state.sucursales.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Todavía no hay sucursales',
                  message: 'La sucursal "Principal" se crea sola al dar de alta el tenant.',
                  actionLabel: 'Nueva sucursal',
                  onAction: () => _abrirFormulario(context),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: state.sucursales.length,
                  separatorBuilder: (context, index) => const SizedBox(height: LavaderoSpacing.sm),
                  itemBuilder: (context, index) {
                    final sucursal = state.sucursales[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.store_mall_directory_outlined),
                        title: Text(sucursal.nombre),
                        subtitle: Text(
                          [
                            if (sucursal.direccion != null && sucursal.direccion!.isNotEmpty)
                              sucursal.direccion!,
                            'Capacidad: ${sucursal.capacidadSimultanea} simultáneas',
                          ].join(' · '),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar',
                          onPressed: () => _abrirFormulario(context, sucursal: sucursal),
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

  void _abrirFormulario(BuildContext context, {Sucursal? sucursal}) {
    showDialog<void>(
      context: context,
      builder: (context) => _SucursalFormDialog(sucursal: sucursal),
    );
  }
}

class _SucursalFormDialog extends ConsumerStatefulWidget {
  const _SucursalFormDialog({this.sucursal});

  final Sucursal? sucursal;

  @override
  ConsumerState<_SucursalFormDialog> createState() => _SucursalFormDialogState();
}

class _SucursalFormDialogState extends ConsumerState<_SucursalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(text: widget.sucursal?.nombre);
  late final _direccionController = TextEditingController(text: widget.sucursal?.direccion);
  late final _capacidadController =
      TextEditingController(text: widget.sucursal?.capacidadSimultanea.toString() ?? '1');

  bool _isLoading = false;
  String? _errorMessage;

  bool get _esEdicion => widget.sucursal != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _direccionController.dispose();
    _capacidadController.dispose();
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
    final controller = ref.read(branchesControllerProvider.notifier);
    try {
      final nombre = _nombreController.text.trim();
      final direccion = _direccionController.text.trim();
      final capacidad = int.parse(_capacidadController.text.trim());
      if (_esEdicion) {
        await controller.actualizar(
          id: widget.sucursal!.id,
          nombre: nombre,
          direccion: direccion.isEmpty ? null : direccion,
          capacidadSimultanea: capacidad,
        );
      } else {
        await controller.crear(
          nombre: nombre,
          direccion: direccion.isEmpty ? null : direccion,
          capacidadSimultanea: capacidad,
        );
      }
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
    return AlertDialog(
      title: Text(_esEdicion ? 'Editar sucursal' : 'Nueva sucursal'),
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
                controller: _direccionController,
                decoration: const InputDecoration(labelText: 'Dirección (opcional)'),
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _capacidadController,
                decoration: const InputDecoration(labelText: 'Capacidad simultánea'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value?.trim() ?? '');
                  return (n == null || n < 1) ? 'Ingresa un número válido' : null;
                },
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
        LoadingButton(onPressed: _guardar, isLoading: _isLoading, child: const Text('Guardar')),
      ],
    );
  }
}
