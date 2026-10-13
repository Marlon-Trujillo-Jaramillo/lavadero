import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import 'application/catalog_pricing_controller.dart';

enum _Filtro { todos, activos, inactivos }

/// Administración del catálogo de servicios del tenant: alta, edición y
/// activar/desactivar. Consume `/api/v1/catalogo/servicios`.
class CatalogPricingScreen extends ConsumerStatefulWidget {
  const CatalogPricingScreen({super.key});

  @override
  ConsumerState<CatalogPricingScreen> createState() =>
      _CatalogPricingScreenState();
}

class _CatalogPricingScreenState extends ConsumerState<CatalogPricingScreen> {
  _Filtro _filtro = _Filtro.todos;

  void _abrirFormulario({ServiceItem? servicio}) {
    showDialog<void>(
      context: context,
      builder: (context) => _ServicioFormDialog(servicio: servicio),
    );
  }

  Future<void> _cambiarEstado(ServiceItem servicio, bool activo) async {
    if (!activo) {
      final confirmado = await ConfirmDialog.show(
        context,
        title: '¿Desactivar "${servicio.nombre}"?',
        message:
            'Tus clientes dejarán de verlo al reservar. Las reservas ya hechas '
            'no cambian y puedes volver a activarlo cuando quieras.',
        confirmLabel: 'Desactivar',
        icon: Icons.visibility_off_outlined,
        destructive: true,
      );
      if (!confirmado) return;
    }
    await ref
        .read(catalogPricingControllerProvider.notifier)
        .cambiarEstado(id: servicio.id, activo: activo);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(catalogPricingControllerProvider);
    final controller = ref.read(catalogPricingControllerProvider.notifier);
    final activos = state.items.where((s) => s.activo).length;
    final inactivos = state.items.length - activos;
    final visibles = switch (_filtro) {
      _Filtro.todos => state.items,
      _Filtro.activos => state.items.where((s) => s.activo).toList(),
      _Filtro.inactivos => state.items.where((s) => !s.activo).toList(),
    };

    return AdminPage(
      toolbar: PageToolbar(
        leading: state.items.isEmpty
            ? null
            : SegmentedButton<_Filtro>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: _Filtro.todos,
                    label: Text('Todos · ${state.items.length}'),
                  ),
                  ButtonSegment(
                    value: _Filtro.activos,
                    label: Text('Activos · $activos'),
                  ),
                  ButtonSegment(
                    value: _Filtro.inactivos,
                    label: Text('Inactivos · $inactivos'),
                  ),
                ],
                selected: {_filtro},
                onSelectionChanged: (seleccion) =>
                    setState(() => _filtro = seleccion.first),
              ),
        actions: [
          FilledButton.icon(
            onPressed: _abrirFormulario,
            icon: const Icon(Icons.add_rounded, size: LavaderoSizes.iconMd),
            label: const Text('Nuevo servicio'),
          ),
        ],
      ),
      banner: state.errorMessage != null
          ? ErrorBanner(
              message: state.errorMessage!,
              onRetry: controller.cargar,
              onDismiss: controller.descartarError,
            )
          : null,
      body: switch (state) {
        CatalogPricingState(isLoading: true, items: []) =>
          const CardGridSkeleton(minItemWidth: 280),
        CatalogPricingState(errorMessage: _?, items: []) =>
          const SizedBox.shrink(),
        CatalogPricingState(items: []) => EmptyState(
          icon: Icons.local_car_wash_outlined,
          title: 'Arma tu menú de servicios',
          message:
              'Agrega lo que ofreces —lavado básico, full, polichado— con su '
              'precio y duración. Tus clientes lo verán al reservar.',
          actionLabel: 'Nuevo servicio',
          onAction: _abrirFormulario,
        ),
        _ when visibles.isEmpty => EmptyState(
          icon: Icons.filter_alt_off_outlined,
          title: _filtro == _Filtro.activos
              ? 'No hay servicios activos'
              : 'No hay servicios inactivos',
          message: _filtro == _Filtro.activos
              ? 'Activa un servicio para que tus clientes puedan reservarlo.'
              : 'Todos tus servicios están visibles para tus clientes.',
        ),
        _ => ListView(
          padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
          children: [
            ResponsiveGrid(
              minItemWidth: 280,
              maxColumns: 3,
              children: [
                for (final servicio in visibles)
                  _ServicioCard(
                    servicio: servicio,
                    cambiandoEstado: state.cambiandoEstadoId == servicio.id,
                    onEditar: () => _abrirFormulario(servicio: servicio),
                    onCambiarEstado: state.cambiandoEstadoId == null
                        ? (activo) => _cambiarEstado(servicio, activo)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      },
    );
  }
}

class _ServicioCard extends StatelessWidget {
  const _ServicioCard({
    required this.servicio,
    required this.cambiandoEstado,
    required this.onEditar,
    required this.onCambiarEstado,
  });

  final ServiceItem servicio;
  final bool cambiandoEstado;
  final VoidCallback onEditar;
  final ValueChanged<bool>? onCambiarEstado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activo = servicio.activo;
    final descripcion = servicio.descripcion?.trim() ?? '';
    return LavaderoCard(
      onTap: onEditar,
      padding: const EdgeInsets.all(LavaderoSpacing.lg - LavaderoSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: servicio.icono,
                color: activo ? servicio.colorAcento : scheme.outline,
              ),
              const Spacer(),
              StatusBadge(
                label: activo ? 'Activo' : 'Inactivo',
                color: activo ? LavaderoColors.success : scheme.outline,
              ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.md),
          Text(
            servicio.nombre,
            style: theme.textTheme.titleMedium?.copyWith(
              color: activo ? null : scheme.onSurfaceVariant,
            ),
          ),
          if (descripcion.isNotEmpty) ...[
            const SizedBox(height: LavaderoSpacing.xs),
            Text(
              descripcion,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          const Spacer(),
          const SizedBox(height: LavaderoSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  Formato.moneda(servicio.precio, servicio.moneda),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFeatures: LavaderoTypography.tabular,
                    color: activo ? null : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              MetaPill(
                icon: Icons.schedule_rounded,
                label: Formato.duracion(
                  Duration(minutes: servicio.duracionEstimadaMinutos),
                ),
              ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.md),
          const Divider(height: LavaderoSizes.hairline),
          const SizedBox(height: LavaderoSpacing.sm),
          Row(
            children: [
              SizedBox(
                height: LavaderoSizes.controlHeightSm,
                child: Center(
                  child: cambiandoEstado
                      ? const InlineSpinner()
                      : Switch(value: activo, onChanged: onCambiarEstado),
                ),
              ),
              const SizedBox(width: LavaderoSpacing.sm),
              Expanded(
                child: Text(
                  activo ? 'Visible al reservar' : 'Oculto para clientes',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEditar,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: LavaderoSizes.iconSm,
                ),
                label: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
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
  late final _nombreController = TextEditingController(
    text: widget.servicio?.nombre,
  );
  late final _descripcionController = TextEditingController(
    text: widget.servicio?.descripcion,
  );
  late final _duracionController = TextEditingController(
    text: widget.servicio?.duracionEstimadaMinutos.toString(),
  );
  late final _precioController = TextEditingController(
    text: widget.servicio?.precio.toStringAsFixed(0),
  );

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

  String get _moneda => widget.servicio?.moneda ?? 'COP';

  /// En COP acepta "45000", "45.000" o "45,000" (separadores de miles al escribir el monto); en
  /// monedas con centavos acepta "12,50" o "12.50".
  double? _parsearPrecio(String texto) {
    final limpio = texto.trim();
    if (_moneda == 'COP') {
      return double.tryParse(limpio.replaceAll('.', '').replaceAll(',', ''));
    }
    return double.tryParse(limpio.replaceAll(',', '.'));
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
      final precio = _parsearPrecio(_precioController.text)!;
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
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moneda = _moneda;
    return LavaderoFormDialog(
      title: _esEdicion ? 'Editar servicio' : 'Nuevo servicio',
      subtitle: _esEdicion
          ? 'El nuevo precio aplica a las reservas que se hagan desde ahora.'
          : 'Aparecerá en el catálogo que ven tus clientes al reservar.',
      icon: Icons.local_car_wash_rounded,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: _esEdicion ? 'Guardar cambios' : 'Crear servicio',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      fields: [
        TextFormField(
          controller: _nombreController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'ej. Lavado full',
            prefixIcon: Icon(Icons.local_car_wash_outlined),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'El nombre es obligatorio'
              : null,
        ),
        TextFormField(
          controller: _descripcionController,
          minLines: 2,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Descripción (opcional)',
            hintText: 'Qué incluye el servicio',
            prefixIcon: Icon(Icons.notes_rounded),
            alignLabelWithHint: true,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _precioController,
                textInputAction: TextInputAction.next,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Precio ($moneda)',
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final precio = _parsearPrecio(value ?? '');
                  return (precio == null || precio <= 0)
                      ? 'Ingresa un precio válido'
                      : null;
                },
              ),
            ),
            const SizedBox(width: LavaderoSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _duracionController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duración',
                  suffixText: 'min',
                  prefixIcon: Icon(Icons.schedule_rounded),
                ),
                validator: (value) {
                  final minutos = int.tryParse(value?.trim() ?? '');
                  return (minutos == null || minutos < 1)
                      ? 'Duración inválida'
                      : null;
                },
                onFieldSubmitted: (_) => _guardar(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
