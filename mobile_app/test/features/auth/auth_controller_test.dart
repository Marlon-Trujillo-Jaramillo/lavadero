import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/auth/application/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late ProviderContainer container;

  final authResponse = AuthResponse(
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresIn: 900,
    user: const UserProfile(
      id: 'u1',
      email: 'cliente@example.com',
      roles: [UserRole.cliente],
    ),
  );

  setUp(() async {
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession())
        .thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
    );
    addTearDown(container.dispose);

    // Dispara build() y deja que el _restoreSession (Future.microtask)
    // inicial termine antes de que cada test interactúe con el controller.
    container.read(authControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('starts as AuthUnauthenticated when there is no cached session', () {
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('login() moves state to AuthAuthenticated with the returned user',
      () async {
    when(
      () => authRepository.login(
        tenantSlug: any(named: 'tenantSlug'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => authResponse);

    await container.read(authControllerProvider.notifier).login(
          tenantSlug: 'lavadero-central',
          email: 'cliente@example.com',
          password: 'secret123',
        );

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthAuthenticated>());
    expect((state as AuthAuthenticated).user.email, 'cliente@example.com');
  });

  test('logout() moves state back to AuthUnauthenticated', () async {
    when(
      () => authRepository.login(
        tenantSlug: any(named: 'tenantSlug'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => authResponse);
    when(() => authRepository.logout()).thenAnswer((_) async {});

    final notifier = container.read(authControllerProvider.notifier);
    await notifier.login(
      tenantSlug: 'lavadero-central',
      email: 'cliente@example.com',
      password: 'secret123',
    );
    await notifier.logout();

    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });

  test('handleSessionExpired() forces AuthUnauthenticated', () {
    container.read(authControllerProvider.notifier).handleSessionExpired();
    expect(container.read(authControllerProvider), isA<AuthUnauthenticated>());
  });
}
