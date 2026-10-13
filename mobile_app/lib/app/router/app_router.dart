import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../core/role_router.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/tenant_selection/presentation/tenant_selection_screen.dart';
import 'app_routes.dart';

/// Puentea cambios de [authControllerProvider] hacia go_router
/// (`refreshListenable`), para que el `redirect` guard se re-evalúe cada vez
/// que cambia el estado de autenticación (login, logout, sesión expirada).
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Ref ref) {
    ref.listen(authControllerProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    // Se arranca en `/home`: mientras la sesión se restaura, `_HomeGate`
    // muestra el splash de marca (antes se veía un destello de la búsqueda
    // de lavaderos aunque hubiera sesión guardada).
    initialLocation: AppRoutes.home,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isPublicRoute =
          location == AppRoutes.tenantSelection ||
          location == AppRoutes.login ||
          location == AppRoutes.register;

      // Mientras se resuelve si hay sesión guardada, no se redirige (evita
      // un parpadeo hacia tenant_selection antes de confirmar la sesión).
      if (authState is AuthUnknown) return null;

      if (authState is AuthAuthenticated && isPublicRoute) {
        return AppRoutes.home;
      }
      if (authState is AuthUnauthenticated && !isPublicRoute) {
        return AppRoutes.tenantSelection;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.tenantSelection,
        builder: (context, state) => const TenantSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const _HomeGate(),
      ),
    ],
  );
});

/// Observa (no solo lee) el estado de sesión. Antes el builder de `/home`
/// hacía `ref.read` y devolvía un `SizedBox` vacío si la sesión aún era
/// desconocida; como la ruta no cambiaba, go_router no lo reconstruía y la
/// pantalla quedaba en blanco. Mismo arreglo que `admin_web`.
class _HomeGate extends ConsumerWidget {
  const _HomeGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    if (authState is AuthAuthenticated) {
      return RoleRouter(user: authState.user);
    }
    return const LavaderoSplash();
  }
}
