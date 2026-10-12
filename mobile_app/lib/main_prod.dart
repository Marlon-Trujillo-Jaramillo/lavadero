import 'app/di/environment.dart';
import 'bootstrap.dart';

Future<void> main() async { 
  await bootstrap(
    const AppEnvironment(
      name: 'prod',
      // Sobreescribible con --dart-define=API_BASE_URL=... — ver main_dev.dart.
      // En prod normalmente no hace falta (el default ya es el correcto),
      // pero mantenerlo consistente entre los tres entry points evita
      // sorpresas si algún día se necesita.
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.lavadero.app',
      ),
    ),
  );
}
