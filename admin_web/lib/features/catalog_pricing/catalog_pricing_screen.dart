import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/catalog_pricing_controller.dart';

/// Administración del catálogo de servicios del tenant: alta, edición y
/// activar/desactivar. Consume `/api/v1/catalogo/servicios`.
class CatalogPricingScreen extends ConsumerWidget {
  const CatalogPricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogPricingControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo servicio'),
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
            else if (state.items.isEmpty)
              const Expanded(
                child: Center(
                  child: Text('Todavía no hay servicios en el catálogo.'),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return ListTile(
                      leading: Icon(
                        Icons.local_car_wash_outlined,
                        color: item.activo
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                      title: Text(item.nombre),
                      subtitle: Text(
                        '${_formatoPrecio(item.precio, item.moneda)} · '
                        '${item.duracionEstimadaMinutos} min'
                        '${item.activo ? '' : ' · Inactivo'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Editar',
                            onPressed: () =>
                                _abrirFormulario(context, servicio: item),
                          ),
                          Switch(
                            value: item.activo,
                            onChanged: (activo) => ref
                                .read(catalogPricingControllerProvider.notifier)
                                .cambiarEstado(id: item.id, activo: activo),
                          ),
                        ],
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

  void _abrirFormulario(BuildContext context, {ServiceItem? servicio}) {
    showDialog<void>(
      context: context,
      builder: (context) => _ServicioFormDialog(servicio: servicio),
    );
  }

  String _formatoPrecio(double precio, String moneda) =>
      '\$${precio.toStringAsFixed(0)} $moneda';
}

class _ServicioFormDialog extends ConsumerStatefulWidget {
  const _ServicioFormDialog({this.servicio});

  final ServiceItem? servicio;

  @override
  ConsumerState<_ServicioFormDialog> createState() =>
      _ServicioFormDialogState();
}

class _ServicioFormDialogState extends ConsumerState<_ServicioFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController =
      TextEditingController(text: widget.servicio?.nombre);
  late final _descripcionController =
      TextEditingController(text: widget.servicio?.descripcion);
  late final _duracionController = TextEditingController(
    text: widget.servicio?.duracionEstimadaMinutos.toString(),
  );
  late final _precioController =
      TextEditingController(text: widget.servicio?.precio.toStringAsFixed(0));

  bool _isLoading = false;
  String? _errorMessage;

  bool get _esEdicion => widget.servicio != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _duracionController.dispose();
    _precioController.dispose();
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
    final controller = ref.read(catalogPricingControllerProvider.notifier);
    try {
      final nombre = _nombreController.text.trim();
      final descripcion = _descripcionController.text.trim();
      final duracion = int.parse(_duracionController.text.trim());
      final precio = double.parse(_precioController.text.trim());
      if (_esEdicion) {
        await controller.actualizar(
          id: widget.servicio!.id,
          nombre: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
          duracionEstimadaMinutos: duracion,
          precio: precio,
        );
      } else {
        await controller.crear(
          nombre: nombre,
          descripcion: descripcion.isEmpty ? null : descripcion,
          duracionEstimadaMinutos: duracion,
          precio: precio,
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
      title: Text(_esEdicion ? 'Editar servicio' : 'Nuevo servicio'),
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
                    (value == null || value.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _descripcionController,
                decoration:
                    const InputDecoration(labelText: 'Descripción (opcional)'),
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _duracionController,
                decoration:
                    const InputDecoration(labelText: 'Duración estimada (min)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final minutos = int.tryParse(value?.trim() ?? '');
                  return (minutos == null || minutos < 1)
                      ? 'Ingresa una duración válida'
                      : null;
                },
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio (COP)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final precio = double.tryParse(value?.trim() ?? '');
                  return (precio == null || precio <= 0)
                      ? 'Ingresa un precio válido'
                      : null;
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
        LoadingButton(
          onPressed: _guardar,
          isLoading: _isLoading,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
