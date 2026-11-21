import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../features/auth/application/auth_controller.dart';
import 'environment.dart';

/// Composición de dependencias de la app, vía Riverpod.
///
/// Decisión de diseño (DI + estado): Riverpod puro (`Notifier`/`Provider`
/// escritos a mano) en vez de un service locator global: es el estándar de
/// facto en Flutter para DI+estado combinados y los providers se sustituyen
/// en tests con `ProviderScope(overrides: [...])`. El proyecto NO usa
/// generación de código (ni `@riverpod`, ni Freezed/json_serializable, ni
/// `build_runner`): modelos y providers se escriben a mano.
///
/// `environmentProvider` se sobreescribe en `bootstrap()` con el
/// [AppEnvironment] del `main_*.dart` que arrancó la app (dev/staging/prod).
final environmentProvider = Provider<AppEnvironment>((ref) {
  throw UnimplementedError(
    'environmentProvider debe sobreescribirse en bootstrap() con un '
    'ProviderScope(overrides: [...]) antes de runApp.',
  );
});

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Slug del tenant elegido en `tenant_selection`. Se usa para el header
/// `X-Tenant-Slug` en llamadas públicas/login, y se mantiene en memoria
/// (no persiste tras cerrar la app: el usuario vuelve a elegir tenant, salvo
/// que ya tenga sesión activa restaurada).
final selectedTenantSlugProvider = StateProvider<String?>((ref) => null);

/// Nombre visible del tenant elegido (para mostrar "Entrando a {lavadero}"
/// en login/registro y la marca en el inicio). Solo presentación: el header
/// sigue usando [selectedTenantSlugProvider].
final selectedTenantNameProvider = StateProvider<String?>((ref) => null);

final apiClientProvider = Provider<ApiClient>((ref) {
  final environment = ref.watch(environmentProvider);
  final tokenStorage = ref.watch(tokenStorageProvider);
  return ApiClient(
    baseUrl: environment.apiBaseUrl,
    tokenStorage: tokenStorage,
    tenantSlugProvider: () => ref.read(selectedTenantSlugProvider),
    onSessionExpired: () =>
        ref.read(authControllerProvider.notifier).handleSessionExpired(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(apiClientProvider).dio,
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final tenantRepositoryProvider = Provider<TenantRepository>((ref) {
  return TenantRepository(dio: ref.watch(apiClientProvider).dio);
});

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  return CatalogRepository(dio: ref.watch(apiClientProvider).dio);
});

final schedulingRepositoryProvider = Provider<SchedulingRepository>((ref) {
  return SchedulingRepository(dio: ref.watch(apiClientProvider).dio);
});

final vehiculoRepositoryProvider = Provider<VehiculoRepository>((ref) {
  return VehiculoRepository(dio: ref.watch(apiClientProvider).dio);
});

final promocionRepositoryProvider = Provider<PromocionRepository>((ref) {
  return PromocionRepository(dio: ref.watch(apiClientProvider).dio);
});
