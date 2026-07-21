/// Configuración por ambiente (dev/staging/prod), inyectada por cada
/// `main_*.dart`. La diferencia entre ambientes es SOLO la configuración
/// (baseUrl de API, nombre), nunca el rol de usuario: el rol se decide en
/// runtime tras el login (ver `core/role_router.dart`).
class AppEnvironment {
  const AppEnvironment({
    required this.name,
    required this.apiBaseUrl,
    // Vacío por defecto (sin cuenta de Sentry creada todavía) = SDK en modo
    // no-op — ver docs/specs/004-observabilidad.md. Cada main_*.dart lo pasa
    // igual vía `String.fromEnvironment('SENTRY_DSN')`.
    this.sentryDsn = const String.fromEnvironment('SENTRY_DSN'),
  });

  final String name;
  final String apiBaseUrl;
  final String sentryDsn;

  @override
  String toString() => 'AppEnvironment($name, $apiBaseUrl)';
}
