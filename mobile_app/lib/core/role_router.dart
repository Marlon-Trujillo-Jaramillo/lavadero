import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../features/client/client_shell.dart';
import '../features/employee/employee_shell.dart';
import '../features/shared/user_display.dart';
import '../features/shared/widgets/profile_menu_button.dart';

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
        user: user,
        onSelected: (asEmployee) =>
            setState(() => _actingAsEmployee = asEmployee),
      );
    }

    final showEmployeeShell = hasBothRoles
        ? _actingAsEmployee!
        : user.isEmpleado;
    return showEmployeeShell ? const EmpleadoShell() : const ClienteShell();
  }
}

class _RoleSelectorScreen extends StatelessWidget {
  const _RoleSelectorScreen({required this.user, required this.onSelected});

  final UserProfile user;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: LavaderoSizes.formMaxWidth,
            ),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(LavaderoSpacing.lg),
              children: [
                const Row(
                  children: [
                    LavaderoLogo(size: LavaderoSizes.iconXl),
                    Spacer(),
                    ProfileMenuButton(),
                  ],
                ),
                const SizedBox(height: LavaderoSpacing.xl),
                FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${user.nombreCorto} 👋',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: LavaderoSpacing.xs),
                      Text(
                        '¿Cómo quieres continuar?',
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: LavaderoSpacing.sm),
                      Text(
                        'Tu cuenta tiene acceso como cliente y como empleado. '
                        'Elige uno para esta sesión.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: LavaderoSpacing.xl),
                FadeSlideIn(
                  index: 1,
                  child: _RoleCard(
                    icon: Icons.local_car_wash_rounded,
                    title: 'Como cliente',
                    message: 'Reserva lavados y sigue el estado de tu auto.',
                    gradient: true,
                    onTap: () => onSelected(false),
                  ),
                ),
                const SizedBox(height: LavaderoSpacing.md),
                FadeSlideIn(
                  index: 2,
                  child: _RoleCard(
                    icon: Icons.badge_rounded,
                    title: 'Como empleado',
                    message:
                        'Agenda del día, checklist e incidencias de tu turno.',
                    onTap: () => onSelected(true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
    this.gradient = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = gradient ? LavaderoColors.white : scheme.onSurface;
    final secondary = gradient
        ? LavaderoColors.onBrandMuted
        : scheme.onSurfaceVariant;
    return Semantics(
      button: true,
      child: LavaderoCard(
        onTap: onTap,
        gradient: gradient ? LavaderoGradients.brandStrong : null,
        padding: const EdgeInsets.all(LavaderoSpacing.lg),
        child: Row(
          children: [
            IconBadge(
              icon: icon,
              size: LavaderoSizes.avatarLg,
              color: gradient ? LavaderoColors.white : LavaderoColors.aqua,
            ),
            const SizedBox(width: LavaderoSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: foreground,
                    ),
                  ),
                  const SizedBox(height: LavaderoSpacing.xxs),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: LavaderoSpacing.sm),
            Icon(Icons.arrow_forward_rounded, color: foreground),
          ],
        ),
      ),
    );
  }
}
