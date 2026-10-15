/// Configuración de ambiente de `admin_web`. A diferencia de `mobile_app`
/// (que tiene tres entry points `main_dev/staging/prod.dart`), esta app web
/// resuelve el ambiente en un único `main.dart` vía `--dart-define`, que es
/// el mecanismo estándar para builds web (`flutter build web
/// --dart-define=API_BASE_URL=...`), evitando triplicar el entry point de
/// una SPA que normalmente se despliega desde un único pipeline por entorno.
class AppEnvironment {
  const AppEnvironment({
    required this.name,
    required this.apiBaseUrl,
    required this.sentryDsn,
  });

  factory AppEnvironment.fromDartDefines() => const AppEnvironment(
    name: String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
    apiBaseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.dev.lavadero.app',
    ),
    // Vacío por defecto (sin cuenta de Sentry creada todavía) = SDK en
    // modo no-op — ver docs/specs/004-observabilidad.md.
    sentryDsn: String.fromEnvironment('SENTRY_DSN'),
  );

  final String name;
  final String apiBaseUrl;
  final String sentryDsn;

  @override
  String toString() => 'AppEnvironment($name, $apiBaseUrl)';
}
