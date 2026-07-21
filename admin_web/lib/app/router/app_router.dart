import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/admin_auth_controller.dart';
import '../../features/auth/presentation/admin_login_screen.dart';
import '../admin_shell.dart';
import 'app_routes.dart';

/// Puentea cambios de [adminAuthControllerProvider] hacia go_router
/// (`refreshListenable`), igual que en `mobile_app`.
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Ref ref) {
    ref.listen(adminAuthControllerProvider, (previous, next) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(adminAuthControllerProvider);
      final isPublicRoute = state.matchedLocation == AppRoutes.login;

      if (authState is AdminAuthUnknown) return null;
      if (authState is AdminAuthAuthenticated && isPublicRoute) {
        return AppRoutes.home;
      }
      if (authState is AdminAuthUnauthenticated && !isPublicRoute) {
        return AppRoutes.login;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          final authState = ref.read(adminAuthControllerProvider);
          if (authState is! AdminAuthAuthenticated) {
            return const SizedBox.shrink();
          }
          return AdminShell(user: authState.user);
        },
      ),
    ],
  );
});
