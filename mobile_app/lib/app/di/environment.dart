/// Configuración por ambiente (dev/staging/prod), inyectada por cada
/// `main_*.dart`. La diferencia entre ambientes es SOLO la configuración
/// (baseUrl de API, nombre), nunca el rol de usuario: el rol se decide en
/// runtime tras el login (ver `core/role_router.dart`).
class AppEnvironment {
  const AppEnvironment({required this.name, required this.apiBaseUrl});

  final String name;
  final String apiBaseUrl;

  @override
  String toString() => 'AppEnvironment($name, $apiBaseUrl)';
}
