import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Estado de autenticación de `admin_web`. El router escucha este provider
/// para decidir a qué pantalla redirigir (mismo patrón que `mobile_app`).
sealed class AdminAuthState {
  const AdminAuthState();
}

class AdminAuthUnknown extends AdminAuthState {
  const AdminAuthUnknown();
}

class AdminAuthUnauthenticated extends AdminAuthState {
  const AdminAuthUnauthenticated();
}

class AdminAuthAuthenticated extends AdminAuthState {
  const AdminAuthAuthenticated(this.user);

  final UserProfile user;
}

final adminAuthControllerProvider =
    NotifierProvider<AdminAuthController, AdminAuthState>(
  AdminAuthController.new,
);

class AdminAuthController extends Notifier<AdminAuthState> {
  @override
  AdminAuthState build() {
    Future.microtask(_restoreSession);
    return const AdminAuthUnknown();
  }

  Future<void> _restoreSession() async {
    final user = await ref.read(authRepositoryProvider).restoreSession();
    state = user != null
        ? AdminAuthAuthenticated(user)
        : const AdminAuthUnauthenticated();
  }

  Future<void> login({
    required String tenantSlug,
    required String email,
    required String password,
  }) async {
    final auth = await ref.read(authRepositoryProvider).login(
          tenantSlug: tenantSlug,
          email: email,
          password: password,
        );
    state = AdminAuthAuthenticated(auth.user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AdminAuthUnauthenticated();
  }

  /// Invocado por `ApiClient.onSessionExpired` cuando un refresh automático
  /// falla (refresh token inválido/expirado): fuerza vuelta a login.
  void handleSessionExpired() {
    state = const AdminAuthUnauthenticated();
  }
}
