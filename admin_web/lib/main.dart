import 'app/di/environment.dart';
import 'bootstrap.dart';

/// Único entry point de `admin_web` (SPA web): el ambiente se resuelve por
/// `--dart-define` (ver `app/di/environment.dart`), no por múltiples
/// `main_*.dart` como en `mobile_app`.
Future<void> main() async {
  await bootstrap(AppEnvironment.fromDartDefines());
}
