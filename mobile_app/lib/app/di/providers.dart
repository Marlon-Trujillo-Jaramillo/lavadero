import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../features/auth/application/auth_controller.dart';
import 'environment.dart';

/// Composición de dependencias de la app, vía Riverpod.
///
/// Decisión de diseño (DI + estado): se eligió Riverpod sobre
/// get_it+injectable porque (a) es el estándar moderno de facto en Flutter
/// para DI+estado combinados, con soporte oficial de primera clase; (b) los
/// providers son testeables por construcción (se pueden sobreescribir en
/// `ProviderScope(overrides: [...])` sin service locator global ni
/// generación de código obligatoria); (c) evita el acoplamiento a
/// `build_runner` que exige `injectable` solo para el registro de
/// dependencias (aquí `build_runner` solo se necesita, si acaso, en
/// `lavadero_core` para freezed/json_serializable).
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
