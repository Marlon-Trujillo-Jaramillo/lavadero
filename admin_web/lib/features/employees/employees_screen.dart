import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import 'application/employees_controller.dart';

/// Staff (rol EMPLEADO) del tenant actual. Antes de esto la única forma de tener un empleado en
/// el sistema era una fila insertada a mano en la base de datos — reemplaza el placeholder
/// "coming soon". Sin sistema de notificaciones todavía: el admin fija la contraseña inicial y se
/// la comunica al empleado fuera de banda (ver `CrearEmpleadoUseCase`, backend).
class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  String _busqueda = '';

  void _abrirFormulario() {
    showDialog<void>(
      context: context,
      builder: (context) => const _EmpleadoFormDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(employeesControllerProvider);
    final controller = ref.read(employeesControllerProvider.notifier);
    final sucursalesPorId = {for (final s in state.sucursales) s.id: s};
    final termino = _busqueda.trim().toLowerCase();
    final visibles = termino.isEmpty
        ? state.empleados
        : state.empleados
              .where(
                (e) =>
                    e.nombre.toLowerCase().contains(termino) ||
                    e.email.toLowerCase().contains(termino),
              )
              .toList();

    return AdminPage(
      toolbar: PageToolbar(
        leading: state.empleados.isEmpty
            ? null
            : _Buscador(
                onChanged: (valor) => setState(() => _busqueda = valor),
              ),
        actions: [
          FilledButton.icon(
            onPressed: _abrirFormulario,
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              size: LavaderoSizes.iconMd,
            ),
            label: const Text('Nuevo empleado'),
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
        EmployeesState(isLoading: true, empleados: []) => const SkeletonList(
          itemCount: 5,
          padding: EdgeInsets.zero,
        ),
        // Si la carga falló no se muestra "no hay empleados": el banner de arriba ya explica.
        EmployeesState(errorMessage: _?, empleados: []) =>
          const SizedBox.shrink(),
        EmployeesState(empleados: []) => EmptyState(
          icon: Icons.groups_outlined,
          title: 'Arma tu equipo',
          message:
              'Da de alta a tus lavadores para que vean su agenda del día y '
              'registren cada servicio desde la app.',
          actionLabel: 'Nuevo empleado',
          onAction: _abrirFormulario,
        ),
        _ when visibles.isEmpty => EmptyState(
          icon: Icons.person_search_outlined,
          title: 'Sin resultados',
          message: 'Ningún empleado coincide con "$_busqueda".',
        ),
        _ => _TablaEmpleados(
          empleados: visibles,
          sucursalesPorId: sucursalesPorId,
        ),
      },
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({required this.onChanged});

  final ValueChanged<String> onChanged;

  static const double _ancho = 320;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ancho,
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre o email',
          prefixIcon: Icon(Icons.search_rounded),
          isDense: true,
        ),
      ),
    );
  }
}

/// Lista con aspecto de tabla: encabezado de columnas en ancho, filas de dos líneas en angosto.
class _TablaEmpleados extends StatelessWidget {
  const _TablaEmpleados({
    required this.empleados,
    required this.sucursalesPorId,
  });

  final List<Empleado> empleados;
  final Map<String, Sucursal> sucursalesPorId;

  static const double _anchoTabla = 760;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth >= _anchoTabla;
        return ListView(
          padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
          children: [
            FadeSlideIn(
              child: LavaderoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (ancho) const _EncabezadoTabla(),
                    for (var i = 0; i < empleados.length; i++) ...[
                      if (i > 0 || ancho)
                        const Divider(height: LavaderoSizes.hairline),
                      _EmpleadoFila(
                        empleado: empleados[i],
                        sucursal: sucursalesPorId[empleados[i].sucursalId],
                        ancho: ancho,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.lg,
        vertical: LavaderoSpacing.smd,
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('EMPLEADO', style: estilo)),
          Expanded(flex: 3, child: Text('SUCURSAL', style: estilo)),
          Expanded(flex: 2, child: Text('ROL', style: estilo)),
          Expanded(
            flex: 2,
            child: Text('ESTADO', style: estilo, textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }
}

class _EmpleadoFila extends StatelessWidget {
  const _EmpleadoFila({
    required this.empleado,
    required this.sucursal,
    required this.ancho,
  });

  final Empleado empleado;
  final Sucursal? sucursal;
  final bool ancho;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final activo = empleado.estado == 'ACTIVO';
    final estado = StatusBadge(
      label: activo ? 'Activo' : 'Bloqueado',
      color: activo ? LavaderoColors.success : scheme.outline,
    );
    final sucursalPill = MetaPill(
      icon: Icons.storefront_outlined,
      label: sucursal?.nombre ?? 'Sin sucursal',
    );
    final identidad = Row(
      children: [
        AvatarInitials(name: empleado.nombre),
        const SizedBox(width: LavaderoSpacing.smd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                empleado.nombre,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                empleado.email,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.lg,
        vertical: LavaderoSpacing.smd,
      ),
      child: ancho
          ? Row(
              children: [
                Expanded(flex: 5, child: identidad),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: sucursalPill,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Empleado',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(alignment: Alignment.centerRight, child: estado),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(child: identidad),
                const SizedBox(width: LavaderoSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    estado,
                    const SizedBox(height: LavaderoSpacing.xs),
                    sucursalPill,
                  ],
                ),
              ],
            ),
    );
  }
}

class _EmpleadoFormDialog extends ConsumerStatefulWidget {
  const _EmpleadoFormDialog();

  @override
  ConsumerState<_EmpleadoFormDialog> createState() =>
      _EmpleadoFormDialogState();
}

class _EmpleadoFormDialogState extends ConsumerState<_EmpleadoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nombreController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _sucursalId;
  bool _ocultarPassword = true;

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
      await ref
          .read(employeesControllerProvider.notifier)
          .crear(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nombre: _nombreController.text.trim(),
            sucursalId: _sucursalId,
          );
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
    final sucursales = ref.watch(employeesControllerProvider).sucursales;

    return LavaderoFormDialog(
      title: 'Nuevo empleado',
      subtitle: 'Podrá ingresar a la app con este email y contraseña.',
      icon: Icons.person_add_alt_1_rounded,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: 'Crear empleado',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      fields: [
        TextFormField(
          controller: _nombreController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nombre completo',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? 'El nombre es obligatorio'
              : null,
        ),
        TextFormField(
          controller: _emailController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
          validator: (value) {
            final email = value?.trim() ?? '';
            return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                ? null
                : 'Ingresa un email válido';
          },
        ),
        TextFormField(
          controller: _passwordController,
          obscureText: _ocultarPassword,
          decoration: InputDecoration(
            labelText: 'Contraseña inicial',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            helperText:
                'Compártela con tu empleado: aún no enviamos invitaciones por email.',
            helperMaxLines: 2,
            suffixIcon: IconButton(
              tooltip: _ocultarPassword
                  ? 'Mostrar contraseña'
                  : 'Ocultar contraseña',
              icon: Icon(
                _ocultarPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () =>
                  setState(() => _ocultarPassword = !_ocultarPassword),
            ),
          ),
          validator: (value) => (value == null || value.length < 8)
              ? 'Mínimo 8 caracteres'
              : null,
        ),
        if (sucursales.isNotEmpty)
          DropdownButtonFormField<String?>(
            initialValue: _sucursalId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Sucursal',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
            items: [
              const DropdownMenuItem<String?>(child: Text('Sin asignar')),
              for (final sucursal in sucursales)
                DropdownMenuItem<String?>(
                  value: sucursal.id,
                  child: Text(sucursal.nombre, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _isLoading
                ? null
                : (id) => setState(() => _sucursalId = id),
          ),
      ],
    );
  }
}
