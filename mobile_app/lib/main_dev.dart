import 'app/di/environment.dart';
import 'bootstrap.dart';

void main() {
  bootstrap(
    const AppEnvironment(
      name: 'dev',
      apiBaseUrl: 'https://api.dev.lavadero.app',
    ),
  );
}
