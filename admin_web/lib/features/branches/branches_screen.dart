import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import 'application/branches_controller.dart';

/// Sucursales del tenant actual. Antes de esto la única forma de que un tenant tuviera más de una
/// sucursal era una inserción manual en la base de datos — reemplaza el placeholder "coming soon".
class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(branchesControllerProvider);
    final controller = ref.read(branchesControllerProvider.notifier);
    final sucursales = state.sucursales;
    final capacidadTotal = sucursales.fold<int>(
      0,
      (total, s) => total + s.capacidadSimultanea,
    );

    return AdminPage(
      toolbar: PageToolbar(
        leading: sucursales.isEmpty
            ? null
            : ToolbarSummary(
                value: '${sucursales.length}',
                label:
                    '${sucursales.length == 1 ? 'sucursal' : 'sucursales'} · '
                    '$capacidadTotal ${capacidadTotal == 1 ? 'puesto' : 'puestos'} de lavado en total',
              ),
        actions: [
          FilledButton.icon(
            onPressed: () => _abrirFormulario(context),
            icon: const Icon(
              Icons.add_business_outlined,
              size: LavaderoSizes.iconMd,
            ),
            label: const Text('Nueva sucursal'),
          ),
        ],
      ),
      banner: state.errorMessage != null
          ? ErrorBanner(
              message: state.errorMessage!,
              onRetry: controller.cargar,
            )
          : null,
      body: switch (state) {
        BranchesState(isLoading: true, sucursales: []) =>
          const CardGridSkeleton(itemCount: 3),
        BranchesState(errorMessage: _?, sucursales: []) =>
          const SizedBox.shrink(),
        BranchesState(sucursales: []) => EmptyState(
          icon: Icons.storefront_outlined,
          title: 'Agrega tu primera sucursal',
          message:
              'Cada sucursal tiene su propia agenda y capacidad. Normalmente la '
              'sucursal "Principal" se crea sola al registrar tu lavadero.',
          actionLabel: 'Nueva sucursal',
          onAction: () => _abrirFormulario(context),
        ),
        _ => ListView(
          padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
          children: [
            ResponsiveGrid(
              minItemWidth: 320,
              maxColumns: 3,
              children: [
                for (final sucursal in sucursales)
                  _SucursalCard(
                    sucursal: sucursal,
                    onEditar: () =>
                        _abrirFormulario(context, sucursal: sucursal),
                  ),
              ],
            ),
          ],
        ),
      },
    );
  }

  void _abrirFormulario(BuildContext context, {Sucursal? sucursal}) {
    showDialog<void>(
      context: context,
      builder: (context) => _SucursalFormDialog(sucursal: sucursal),
    );
  }
}

class _SucursalCard extends StatelessWidget {
  const _SucursalCard({required this.sucursal, required this.onEditar});

  final Sucursal sucursal;
  final VoidCallback onEditar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final direccion = sucursal.direccion?.trim() ?? '';
    return LavaderoCard(
      onTap: onEditar,
      padding: const EdgeInsets.all(LavaderoSpacing.lg - LavaderoSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconBadge(icon: Icons.storefront_rounded),
              const Spacer(),
              IconButton(
                tooltip: 'Editar sucursal',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: LavaderoSizes.iconMd,
                ),
                onPressed: onEditar,
              ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.md),
          Text(sucursal.nombre, style: theme.textTheme.titleMedium),
          const SizedBox(height: LavaderoSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.place_outlined,
                size: LavaderoSizes.iconSm,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: LavaderoSpacing.xs),
              Expanded(
                child: Text(
                  direccion.isEmpty ? 'Sin dirección registrada' : direccion,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          const SizedBox(height: LavaderoSpacing.md),
          const Divider(height: LavaderoSizes.hairline),
          const SizedBox(height: LavaderoSpacing.md),
          _Capacidad(puestos: sucursal.capacidadSimultanea),
        ],
      ),
    );
  }
}

/// Capacidad simultánea como fila de "puestos" (uno por auto que se puede atender a la vez).
class _Capacidad extends StatelessWidget {
  const _Capacidad({required this.puestos});

  final int puestos;

  static const int _maxVisibles = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final visibles = puestos.clamp(0, _maxVisibles);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Capacidad',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: LavaderoSpacing.xxs),
              Text(
                puestos == 1 ? '1 auto a la vez' : '$puestos autos a la vez',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: LavaderoTypography.tabular,
                ),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: LavaderoSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var i = 0; i < visibles; i++)
              Container(
                width: LavaderoSizes.iconLg,
                height: LavaderoSizes.iconLg,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(LavaderoRadii.xs),
                ),
                child: Icon(
                  Icons.directions_car_rounded,
                  size: LavaderoSizes.iconSm,
                  color: scheme.primary,
                ),
              ),
            if (puestos > _maxVisibles)
              Text(
                '+${puestos - _maxVisibles}',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _SucursalFormDialog extends ConsumerStatefulWidget {
  const _SucursalFormDialog({this.sucursal});

  final Sucursal? sucursal;

  @override
  ConsumerState<_SucursalFormDialog> createState() =>
      _SucursalFormDialogState();
}

class _SucursalFormDialogState extends ConsumerState<_SucursalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(
    text: widget.sucursal?.nombre,
  );
  late final _direccionController = TextEditingController(
    text: widget.sucursal?.direccion,
  );
  late final _capacidadController = TextEditingController(
    text: widget.sucursal?.capacidadSimultanea.toString() ?? '1',
  );

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
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LavaderoFormDialog(
      title: _esEdicion ? 'Editar sucursal' : 'Nueva sucursal',
      subtitle: _esEdicion
          ? 'Los cambios de capacidad aplican a las próximas reservas.'
          : 'Tendrá su propia agenda y capacidad de atención.',
      icon: _esEdicion ? Icons.storefront_rounded : Icons.add_business_outlined,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: _esEdicion ? 'Guardar cambios' : 'Crear sucursal',
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
            hintText: 'ej. Sede Norte',
            prefixIcon: Icon(Icons.storefront_outlined),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'El nombre es obligatorio'
              : null,
        ),
        TextFormField(
          controller: _direccionController,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Dirección (opcional)',
            prefixIcon: Icon(Icons.place_outlined),
          ),
        ),
        TextFormField(
          controller: _capacidadController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Capacidad simultánea',
            prefixIcon: Icon(Icons.directions_car_outlined),
            helperText: 'Cuántos autos puedes lavar al mismo tiempo.',
          ),
          validator: (value) {
            final n = int.tryParse(value?.trim() ?? '');
            return (n == null || n < 1)
                ? 'Ingresa un número entero mayor a 0'
                : null;
          },
          onFieldSubmitted: (_) => _guardar(),
        ),
      ],
    );
  }
}
