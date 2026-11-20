/// Paquete compartido del SaaS Lavadero.
///
/// Consumido como path dependency por `mobile_app` y `admin_web`. Expone:
/// - `network`: [ApiClient] (Dio) + interceptores de auth/refresh/tenant +
///   [ApiException].
/// - `models`: DTOs escritos a mano (sin codegen) del contrato `/api/v1`.
/// - `auth`: [TokenStorage], [AuthRepository], [TenantRepository].
/// - `format`: [Formato] para montos, fechas y horas.
/// - `theme`: design system "Aqua" (tokens + ThemeData claro/oscuro).
/// - `widgets`: componentes compartidos (tarjetas, KPIs, estados vacíos,
///   esqueletos de carga, layout de acceso, logo...).
library lavadero_core;

export 'src/auth/auth.dart';
export 'src/billing/billing.dart';
export 'src/catalog/catalog.dart';
export 'src/crm/crm.dart';
export 'src/format/formato.dart';
export 'src/identity/identity.dart';
export 'src/models/models.dart';
export 'src/network/network.dart';
export 'src/scheduling/scheduling.dart';
export 'src/theme/theme.dart';
export 'src/widgets/widgets.dart';
