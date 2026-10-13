import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Estado de autenticación de la app. El router (`app/router/app_router.dart`)
/// escucha este provider para decidir a qué pantalla redirigir.
sealed class AuthState {
  const AuthState();
}

/// Estado inicial mientras se intenta restaurar una sesión guardada.
class AuthUnknown extends AuthState {
  const AuthUnknown();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final UserProfile user;
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Al construirse (arranque de la app), intenta restaurar la sesión
    // cacheada localmente (ver AuthRepository.restoreSession) sin bloquear
    // el estado inicial.
    Future.microtask(_restoreSession);
    return const AuthUnknown();
  }

  Future<void> _restoreSession() async {
    final user = await ref.read(authRepositoryProvider).restoreSession();
    state = user != null
        ? AuthAuthenticated(user)
        : const AuthUnauthenticated();
  }

  Future<void> login({
    required String tenantSlug,
    required String email,
    required String password,
  }) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .login(tenantSlug: tenantSlug, email: email, password: password);
    state = AuthAuthenticated(auth.user);
  }

  Future<void> register({
    required String tenantSlug,
    required String email,
    required String password,
    required String nombre,
  }) async {
    final auth = await ref
        .read(authRepositoryProvider)
        .register(
          tenantSlug: tenantSlug,
          email: email,
          password: password,
          nombre: nombre,
        );
    state = AuthAuthenticated(auth.user);
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AuthUnauthenticated();
  }

  /// Invocado por `ApiClient.onSessionExpired` cuando un refresh automático
  /// falla (refresh token inválido/expirado): fuerza vuelta a login.
  void handleSessionExpired() {
    state = const AuthUnauthenticated();
  }
}
