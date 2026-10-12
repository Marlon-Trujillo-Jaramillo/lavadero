import 'main_dev.dart' as dev;

/// Entry point por defecto (usado cuando se corre sin `-t`, p. ej. desde el
/// botón "Run" del IDE). Delega a `main_dev.dart` — los ambientes reales se
/// seleccionan explícitamente con `flutter run -t lib/main_<env>.dart`.
Future<void> main() async {
  await dev.main();
}
