import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/di/environment.dart';
import 'app/di/providers.dart';

/// Punto de arranque común a los tres `main_*.dart` (dev/staging/prod). Cada
/// entry point solo difiere en el [AppEnvironment] que le pasa a `bootstrap`
/// (básicamente, la `baseUrl` de la API); la app en sí es idéntica.
///
/// Envuelve el arranque con Sentry (ver docs/specs/004-observabilidad.md):
/// captura errores no manejados de Flutter/Dart automáticamente. Con
/// `sentryDsn` vacío, el SDK queda en modo no-op.
Future<void> bootstrap(AppEnvironment environment) async {
  await SentryFlutter.init(
    (options) {
      options.dsn = environment.sentryDsn;
      options.environment = environment.name;
      options.tracesSampleRate = 0.1;
    },
    appRunner: () => runApp(
      ProviderScope(
        overrides: [environmentProvider.overrideWithValue(environment)],
        child: const LavaderoApp(),
      ),
    ),
  );
}
