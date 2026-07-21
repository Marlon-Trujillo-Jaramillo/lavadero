import 'package:admin_web/app/di/providers.dart';
import 'package:admin_web/features/auth/application/admin_auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
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
      id: 'admin1',
      email: 'dueno@example.com',
      roles: [UserRole.adminTenant],
      tenantId: 't1',
    ),
  );

  setUp(() async {
    authRepository = MockAuthRepository();
    when(() => authRepository.restoreSession())
        .thenAnswer((_) async => null);

    container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
    );
    addTearDown(container.dispose);

    container.read(adminAuthControllerProvider);
    await Future<void>.delayed(Duration.zero);
  });

  test('starts as AdminAuthUnauthenticated with no cached session', () {
    expect(
      container.read(adminAuthControllerProvider),
      isA<AdminAuthUnauthenticated>(),
    );
  });

  test('login() moves state to AdminAuthAuthenticated', () async {
    when(
      () => authRepository.login(
        tenantSlug: any(named: 'tenantSlug'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => authResponse);

    await container.read(adminAuthControllerProvider.notifier).login(
          tenantSlug: 'lavadero-central',
          email: 'dueno@example.com',
          password: 'secret123',
        );

    final state = container.read(adminAuthControllerProvider);
    expect(state, isA<AdminAuthAuthenticated>());
    expect(
      (state as AdminAuthAuthenticated).user.roles,
      contains(UserRole.adminTenant),
    );
  });

  test('logout() moves state back to AdminAuthUnauthenticated', () async {
    when(
      () => authRepository.login(
        tenantSlug: any(named: 'tenantSlug'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => authResponse);
    when(() => authRepository.logout()).thenAnswer((_) async {});

    final notifier = container.read(adminAuthControllerProvider.notifier);
    await notifier.login(
      tenantSlug: 'lavadero-central',
      email: 'dueno@example.com',
      password: 'secret123',
    );
    await notifier.logout();

    expect(
      container.read(adminAuthControllerProvider),
      isA<AdminAuthUnauthenticated>(),
    );
  });

  test('handleSessionExpired() forces AdminAuthUnauthenticated', () {
    container.read(adminAuthControllerProvider.notifier).handleSessionExpired();
    expect(
      container.read(adminAuthControllerProvider),
      isA<AdminAuthUnauthenticated>(),
    );
  });
}
