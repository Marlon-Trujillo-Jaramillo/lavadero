import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../features/client/client_shell.dart';
import '../features/employee/employee_shell.dart';

/// Tras el login, decide si mostrar [ClienteShell] o [EmpleadoShell] según
/// los roles del usuario autenticado. Si el usuario tiene ambos roles
/// (CLIENTE y EMPLEADO), se muestra primero un selector simple para que
/// elija con qué shell entra en esta sesión de la app.
class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key, required this.user});

  final UserProfile user;

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  bool? _actingAsEmployee;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final hasBothRoles = user.isCliente && user.isEmpleado;

    if (hasBothRoles && _actingAsEmployee == null) {
      return _RoleSelectorScreen(
        onSelected: (asEmployee) =>
            setState(() => _actingAsEmployee = asEmployee),
      );
    }

    final showEmployeeShell =
        hasBothRoles ? _actingAsEmployee! : user.isEmpleado;
    return showEmployeeShell ? const EmpleadoShell() : const ClienteShell();
  }
}

class _RoleSelectorScreen extends StatelessWidget {
  const _RoleSelectorScreen({required this.onSelected});

  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo quieres continuar?')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.icon(
              icon: const Icon(Icons.person_outline),
              label: const Text('Como cliente'),
              onPressed: () => onSelected(false),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.badge_outlined),
              label: const Text('Como empleado'),
              onPressed: () => onSelected(true),
            ),
          ],
        ),
      ),
    );
  }
}
