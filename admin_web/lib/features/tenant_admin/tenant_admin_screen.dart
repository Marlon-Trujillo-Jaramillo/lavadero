import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/subscription_plan_controller.dart';

/// Solo visible para SUPER_ADMIN: catálogo de planes de suscripción de la
/// plataforma. Consume `/api/v1/plataforma/planes`.
class TenantAdminScreen extends ConsumerWidget {
  const TenantAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subscriptionPlanControllerProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo plan'),
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
            else if (state.planes.isEmpty)
              Expanded(
                child: EmptyState(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Todavía no hay planes de suscripción',
                  message: 'Creá el primer plan para poder dar de alta tenants.',
                  actionLabel: 'Nuevo plan',
                  onAction: () => _abrirFormulario(context),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisSpacing: LavaderoSpacing.md,
                    crossAxisSpacing: LavaderoSpacing.md,
                    mainAxisExtent: 260,
                  ),
                  itemCount: state.planes.length,
                  itemBuilder: (context, index) =>
                      _PlanCard(plan: state.planes[index], onEditar: _abrirFormulario),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _abrirFormulario(BuildContext context, {SubscriptionPlan? plan}) {
    showDialog<void>(
      context: context,
      builder: (context) => _PlanFormDialog(plan: plan),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.onEditar});

  final SubscriptionPlan plan;
  final void Function(BuildContext context, {SubscriptionPlan? plan}) onEditar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(plan.nombre, style: Theme.of(context).textTheme.titleMedium),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                  onPressed: () => onEditar(context, plan: plan),
                ),
              ],
            ),
            Text(
              '\$${plan.precio.toStringAsFixed(0)} ${plan.moneda}/mes',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: LavaderoSpacing.sm),
            Text('Hasta ${plan.maxSucursales} sucursales'),
            Text('Hasta ${plan.maxEmpleados} empleados'),
            const SizedBox(height: LavaderoSpacing.sm),
            if (plan.features.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    for (final feature in plan.features)
                      Padding(
                        padding: const EdgeInsets.only(bottom: LavaderoSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: LavaderoSpacing.xs),
                            Expanded(child: Text(feature)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanFormDialog extends ConsumerStatefulWidget {
  const _PlanFormDialog({this.plan});

  final SubscriptionPlan? plan;

  @override
  ConsumerState<_PlanFormDialog> createState() => _PlanFormDialogState();
}

class _PlanFormDialogState extends ConsumerState<_PlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nombreController = TextEditingController(text: widget.plan?.nombre);
  late final _precioController =
      TextEditingController(text: widget.plan?.precio.toStringAsFixed(0));
  late final _maxSucursalesController =
      TextEditingController(text: widget.plan?.maxSucursales.toString() ?? '1');
  late final _maxEmpleadosController =
      TextEditingController(text: widget.plan?.maxEmpleados.toString() ?? '1');
  late final _featuresController =
      TextEditingController(text: widget.plan?.features.join(', '));

  bool _isLoading = false;
  String? _errorMessage;

  bool get _esEdicion => widget.plan != null;

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _maxSucursalesController.dispose();
    _maxEmpleadosController.dispose();
    _featuresController.dispose();
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
    final controller = ref.read(subscriptionPlanControllerProvider.notifier);
    try {
      final nombre = _nombreController.text.trim();
      final precio = double.parse(_precioController.text.trim());
      final maxSucursales = int.parse(_maxSucursalesController.text.trim());
      final maxEmpleados = int.parse(_maxEmpleadosController.text.trim());
      final features = _featuresController.text
          .split(',')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();
      if (_esEdicion) {
        await controller.actualizar(
          id: widget.plan!.id,
          nombre: nombre,
          precio: precio,
          maxSucursales: maxSucursales,
          maxEmpleados: maxEmpleados,
          features: features,
        );
      } else {
        await controller.crear(
          nombre: nombre,
          precio: precio,
          maxSucursales: maxSucursales,
          maxEmpleados: maxEmpleados,
          features: features,
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
      title: Text(_esEdicion ? 'Editar plan' : 'Nuevo plan'),
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
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio mensual (COP)'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  final precio = double.tryParse(value?.trim() ?? '');
                  return (precio == null || precio <= 0) ? 'Ingresa un precio válido' : null;
                },
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _maxSucursalesController,
                decoration: const InputDecoration(labelText: 'Máx. sucursales'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value?.trim() ?? '');
                  return (n == null || n < 1) ? 'Ingresa un número válido' : null;
                },
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _maxEmpleadosController,
                decoration: const InputDecoration(labelText: 'Máx. empleados'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final n = int.tryParse(value?.trim() ?? '');
                  return (n == null || n < 1) ? 'Ingresa un número válido' : null;
                },
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _featuresController,
                decoration: const InputDecoration(
                  labelText: 'Features (separadas por coma)',
                ),
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
