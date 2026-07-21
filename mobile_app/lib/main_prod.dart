import 'app/di/environment.dart';
import 'bootstrap.dart';

void main() {
  bootstrap(
    const AppEnvironment(
      name: 'prod',
      apiBaseUrl: 'https://api.lavadero.app',
    ),
  );
}
