import 'app/di/environment.dart';
import 'bootstrap.dart';

Future<void> main() async {
  await bootstrap(
    const AppEnvironment(
      name: 'dev',
      // Sobreescribible con `--dart-define=API_BASE_URL=http://localhost:8080`
      // (o `http://10.0.2.2:8080` en emulador Android) para probar contra un
      // backend local sin tocar este archivo.
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api.dev.lavadero.app',
      ),
    ),
  );
}
