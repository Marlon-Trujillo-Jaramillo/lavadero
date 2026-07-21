import 'app/di/environment.dart';
import 'bootstrap.dart';

Future<void> main() async {
  await bootstrap(
    const AppEnvironment(
      name: 'staging',
      // Sobreescribible con --dart-define=API_BASE_URL=... — ver main_dev.dart.
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.staging.lavadero.app',
      ),
    ),
  );
}
