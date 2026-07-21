import 'app/di/environment.dart';
import 'bootstrap.dart';

void main() {
  bootstrap(
    const AppEnvironment(
      name: 'staging',
      apiBaseUrl: 'https://api.staging.lavadero.app',
    ),
  );
}
