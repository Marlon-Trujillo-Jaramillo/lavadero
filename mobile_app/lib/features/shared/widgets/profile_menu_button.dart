import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../user_display.dart';

/// Avatar del usuario en la cabecera de cada pantalla; al tocarlo abre una
/// hoja con la cuenta y "Cerrar sesión" (que antes era un destino más de la
/// barra de navegación).
class ProfileMenuButton extends ConsumerWidget {
  const ProfileMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;
    return Tooltip(
      message: 'Tu cuenta',
      child: Pressable(
        pressedScale: 0.92,
        borderRadius: BorderRadius.circular(LavaderoRadii.full),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (_) => _ProfileSheet(user: user),
        ),
        child: Semantics(
          button: true,
          label: 'Tu cuenta',
          child: AvatarInitials(name: user.email),
        ),
      ),
    );
  }
}

class _ProfileSheet extends ConsumerStatefulWidget {
  const _ProfileSheet({required this.user});

  final UserProfile user;

  @override
  ConsumerState<_ProfileSheet> createState() => _ProfileSheetState();
}

class _ProfileSheetState extends ConsumerState<_ProfileSheet> {
  bool _saliendo = false;

  Future<void> _logout() async {
    setState(() => _saliendo = true);
    final navigator = Navigator.of(context);
    await ref.read(authControllerProvider.notifier).logout();
    if (navigator.mounted && navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final user = widget.user;
    final tenant = ref.watch(selectedTenantNameProvider);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LavaderoSpacing.lg,
          0,
          LavaderoSpacing.lg,
          LavaderoSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                AvatarInitials(name: user.email, size: LavaderoSizes.avatarLg),
                const SizedBox(width: LavaderoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.nombreCorto, style: theme.textTheme.titleLarge),
                      const SizedBox(height: LavaderoSpacing.xxs),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: LavaderoSpacing.md),
            Wrap(
              spacing: LavaderoSpacing.sm,
              runSpacing: LavaderoSpacing.sm,
              children: [
                for (final rol in user.rolesLegibles)
                  StatusBadge(label: rol, color: scheme.primary),
                if (tenant != null)
                  StatusBadge(label: tenant, color: LavaderoColors.aqua),
              ],
            ),
            const SizedBox(height: LavaderoSpacing.lg),
            OutlinedButton.icon(
              onPressed: _saliendo ? null : _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.error,
                side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
              ),
              icon: _saliendo
                  ? InlineSpinner(
 size: LavaderoSizes.iconSm,
 color: scheme.error,
 )
                  : const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
