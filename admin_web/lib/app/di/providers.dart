import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../features/auth/application/admin_auth_controller.dart';
import 'environment.dart';

/// Composición de dependencias de `admin_web`, vía Riverpod — mismo patrón y
/// justificación que en `mobile_app/lib/app/di/providers.dart` (estándar
/// moderno de DI+estado en Flutter, testeable sin service locator global).
final environmentProvider = Provider<AppEnvironment>((ref) {
  throw UnimplementedError(
    'environmentProvider debe sobreescribirse en bootstrap() con un '
    'ProviderScope(overrides: [...]) antes de runApp.',
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// A diferencia de `mobile_app` (que tiene una pantalla `tenant_selection`
/// pública de búsqueda), en `admin_web` el dueño/super-admin ya conoce el
/// slug de su propio tenant, así que se captura directamente en el form de
/// login (ver `features/auth/presentation/admin_login_screen.dart`).
final selectedTenantSlugProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  final environment = ref.watch(environmentProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    baseUrl: environment.apiBaseUrl,
    tokenStorage: tokenStorage,
    tenantSlugProvider: () => ref.read(selectedTenantSlugProvider),
    onSessionExpired: () =>
        ref.read(adminAuthControllerProvider.notifier).handleSessionExpired(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(apiClientProvider).dio,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(dio: ref.watch(apiClientProvider).dio);
});

final schedulingRepositoryProvider = Provider<SchedulingRepository>((ref) {
  return SchedulingRepository(dio: ref.watch(apiClientProvider).dio);
});
