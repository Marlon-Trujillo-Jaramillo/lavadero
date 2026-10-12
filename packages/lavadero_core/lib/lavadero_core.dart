/// Paquete compartido del SaaS Lavadero.
///
/// Consumido como path dependency por `mobile_app` y `admin_web`. Expone:
/// - `network`: [ApiClient] (Dio) + interceptores de auth/refresh/tenant +
///   [ApiException].
/// - `models`: DTOs escritos a mano (sin codegen) del contrato `/api/v1`.
/// - `auth`: [TokenStorage], [AuthRepository], [TenantRepository].
/// - `theme`: design tokens compartidos.
/// - `widgets`: widgets básicos compartidos (LoadingButton, ErrorBanner).
library lavadero_core;

export 'src/auth/auth.dart';
export 'src/catalog/catalog.dart';
export 'src/identity/identity.dart';
export 'src/models/models.dart';
export 'src/network/network.dart';
export 'src/scheduling/scheduling.dart';
export 'src/theme/theme.dart';
export 'src/widgets/widgets.dart';
