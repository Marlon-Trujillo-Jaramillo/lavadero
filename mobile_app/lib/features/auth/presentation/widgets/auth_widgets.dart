import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../../app/di/providers.dart';
import '../../../../app/router/app_routes.dart';

/// "Entrando a {lavadero}": confirma a qué tenant se va a iniciar sesión o
/// registrar, con atajo para cambiarlo.
class SelectedTenantCard extends ConsumerWidget {
  const SelectedTenantCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final slug = ref.watch(selectedTenantSlugProvider) ?? '';
    final nombre = ref.watch(selectedTenantNameProvider) ?? slug;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LavaderoSpacing.smd,
        LavaderoSpacing.smd,
        LavaderoSpacing.xs,
        LavaderoSpacing.smd,
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(LavaderoRadii.md),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          AvatarInitials(name: nombre),
          const SizedBox(width: LavaderoSpacing.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Entrando a',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.75),
                  ),
                ),
                Text(
                  nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.go(AppRoutes.tenantSelection),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }
}

/// "¿No tienes cuenta? Regístrate" — enlace entre login y registro.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    super.key,
    required this.question,
    required this.action,
    required this.onPressed,
  });

  final String question;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          question,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(action)),
      ],
    );
  }
}

/// Botón "volver" redondeado para la cabecera de las pantallas de acceso.
class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      tooltip: 'Volver',
      onPressed: onPressed,
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
