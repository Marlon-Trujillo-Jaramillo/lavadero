import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'app/app.dart';
import 'app/di/environment.dart';
import 'app/di/providers.dart';

/// Envuelve el arranque con Sentry (ver docs/specs/004-observabilidad.md):
/// captura errores no manejados de Flutter/Dart automáticamente. Con
/// `sentryDsn` vacío, el SDK queda en modo no-op — no cambia comportamiento
/// observable en dev/tests sin cuenta de Sentry configurada.
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
        child: const AdminWebApp(),
      ),
    ),
  );
}
