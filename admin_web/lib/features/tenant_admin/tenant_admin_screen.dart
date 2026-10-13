import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import '../shared/widgets/plan_pricing_card.dart';
import 'application/subscription_plan_controller.dart';
import 'application/tenant_directory_controller.dart';

/// Solo visible para SUPER_ADMIN: catálogo de planes de suscripción de la plataforma
/// (`/api/v1/plataforma/planes`) y directorio de lavaderos activos (`/api/v1/tenants`).
class TenantAdminScreen extends ConsumerWidget {
  const TenantAdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planes = ref.watch(subscriptionPlanControllerProvider);
    final planesController = ref.read(
      subscriptionPlanControllerProvider.notifier,
    );
    final directorio = ref.watch(tenantDirectoryControllerProvider);

    return AdminPage(
      toolbar: PageToolbar(
        leading: planes.isLoading && planes.planes.isEmpty
            ? null
            : ToolbarSummary(
                value: '${planes.planes.length}',
                label: planes.planes.length == 1
                    ? 'plan publicado'
                    : 'planes publicados',
              ),
        actions: [
          FilledButton.icon(
            onPressed: () => _abrirFormulario(context),
            icon: const Icon(Icons.add_rounded, size: LavaderoSizes.iconMd),
            label: const Text('Nuevo plan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
        children: [
          const SectionHeader(
            title: 'Planes de suscripción',
            subtitle: 'Lo que paga cada lavadero por usar la plataforma.',
          ),
          if (planes.errorMessage != null) ...[
            ErrorBanner(
              message: planes.errorMessage!,
              onRetry: planesController.cargar,
            ),
            const SizedBox(height: LavaderoSpacing.md),
          ],
          if (planes.isLoading && planes.planes.isEmpty)
            const CardGridSkeleton(
              itemCount: 3,
              itemHeight: PlanPricingCard.alturaEsqueleto,
              minItemWidth: 260,
            )
          else if (planes.planes.isEmpty && planes.errorMessage == null)
            LavaderoCard(
              child: EmptyState(
                minHeight: LavaderoSizes.emptyStateMinHeight,
                icon: Icons.workspace_premium_outlined,
                title: 'Todavía no hay planes',
                message:
                    'Crea el primer plan para poder dar de alta lavaderos.',
                actionLabel: 'Nuevo plan',
                onAction: () => _abrirFormulario(context),
              ),
            )
          else if (planes.planes.isNotEmpty)
            ResponsiveGrid(
              minItemWidth: 260,
              children: [
                for (final plan in planes.planes)
                  PlanPricingCard(
                    plan: plan,
                    onTap: () => _abrirFormulario(context, plan: plan),
                    accion: OutlinedButton.icon(
                      onPressed: () => _abrirFormulario(context, plan: plan),
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: LavaderoSizes.iconSm,
                      ),
                      label: const Text('Editar plan'),
                    ),
                  ),
              ],
            ),
          const SizedBox(height: LavaderoSpacing.xl),
          _DirectorioLavaderos(state: directorio),
        ],
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

class _DirectorioLavaderos extends ConsumerWidget {
  const _DirectorioLavaderos({required this.state});

  final TenantDirectoryState state;

  static const double _anchoBuscador = 280;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(tenantDirectoryControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: 'Lavaderos activos',
          subtitle: state.isLoading
              ? 'Buscando…'
              : '${state.tenants.length} '
                    '${state.tenants.length == 1 ? 'lavadero' : 'lavaderos'}'
                    '${state.query.trim().isEmpty ? ' en la plataforma' : ' encontrados'}',
          trailing: SizedBox(
            width: _anchoBuscador,
            child: TextField(
              onChanged: controller.buscar,
              decoration: const InputDecoration(
                hintText: 'Buscar lavadero',
                prefixIcon: Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
        ),
        if (state.errorMessage != null)
          ErrorBanner(message: state.errorMessage!, onRetry: controller.cargar)
        else if (state.isLoading && state.tenants.isEmpty)
          const SkeletonList.inline()
        else if (state.tenants.isEmpty)
          LavaderoCard(
            child: Padding(
              padding: const EdgeInsets.all(LavaderoSpacing.lg),
              child: Text(
                state.query.trim().isEmpty
                    ? 'Aún no hay lavaderos activos en la plataforma.'
                    : 'Ningún lavadero coincide con "${state.query.trim()}".',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          FadeSlideIn(
            child: LavaderoCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < state.tenants.length; i++) ...[
                    if (i > 0) const Divider(height: LavaderoSizes.hairline),
                    _TenantFila(tenant: state.tenants[i]),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TenantFila extends StatelessWidget {
  const _TenantFila({required this.tenant});

  final TenantSummary tenant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.lg,
        vertical: LavaderoSpacing.smd,
      ),
      child: Row(
        children: [
          AvatarInitials(name: tenant.nombre),
          const SizedBox(width: LavaderoSpacing.smd),
          Expanded(
            child: Text(
              tenant.nombre,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          MetaPill(icon: Icons.link_rounded, label: tenant.slug),
          const SizedBox(width: LavaderoSpacing.sm),
          const StatusBadge(label: 'Activo', color: LavaderoColors.success),
        ],
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
  late final _nombreController = TextEditingController(
    text: widget.plan?.nombre,
  );
  late final _precioController = TextEditingController(
    text: widget.plan?.precio.toStringAsFixed(0),
  );
  late final _maxSucursalesController = TextEditingController(
    text: widget.plan?.maxSucursales.toString() ?? '1',
  );
  late final _maxEmpleadosController = TextEditingController(
    text: widget.plan?.maxEmpleados.toString() ?? '1',
  );
  late final _featuresController = TextEditingController(
    text: widget.plan?.features.join('\n'),
  );

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

  /// Precio en COP: acepta "99000" o "99.000".
  double? _parsearPrecio(String texto) =>
      double.tryParse(texto.trim().replaceAll('.', '').replaceAll(',', ''));

  String? _validarEntero(String? value) {
    final n = int.tryParse(value?.trim() ?? '');
    return (n == null || n < 1) ? 'Mínimo 1' : null;
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
      final precio = _parsearPrecio(_precioController.text)!;
      final maxSucursales = int.parse(_maxSucursalesController.text.trim());
      final maxEmpleados = int.parse(_maxEmpleadosController.text.trim());
      // Una por línea (o separadas por coma, como antes).
      final features = _featuresController.text
          .split(RegExp(r'[\n,]'))
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
      title: _esEdicion ? 'Editar plan' : 'Nuevo plan',
      subtitle: _esEdicion
          ? 'Los lavaderos verán los cambios en su próximo cobro.'
          : 'Quedará disponible para los lavaderos de la plataforma.',
      icon: Icons.workspace_premium_rounded,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: _esEdicion ? 'Guardar cambios' : 'Crear plan',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      fields: [
        TextFormField(
          controller: _nombreController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'ej. Profesional',
            prefixIcon: Icon(Icons.workspace_premium_outlined),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'El nombre es obligatorio'
              : null,
        ),
        TextFormField(
          controller: _precioController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Precio mensual (COP)',
            prefixIcon: Icon(Icons.payments_outlined),
          ),
          validator: (value) {
            final precio = _parsearPrecio(value ?? '');
            return (precio == null || precio <= 0)
                ? 'Ingresa un precio válido'
                : null;
          },
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _maxSucursalesController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Máx. sucursales',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: _validarEntero,
              ),
            ),
            const SizedBox(width: LavaderoSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _maxEmpleadosController,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Máx. empleados',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: _validarEntero,
              ),
            ),
          ],
        ),
        TextFormField(
          controller: _featuresController,
          minLines: 3,
          maxLines: 6,
          keyboardType: TextInputType.multiline,
          decoration: const InputDecoration(
            labelText: 'Qué incluye',
            hintText: 'Una característica por línea',
            prefixIcon: Icon(Icons.checklist_rounded),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }
}
