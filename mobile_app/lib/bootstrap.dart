import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/di/environment.dart';
import 'app/di/providers.dart';

/// Punto de arranque común a los tres `main_*.dart` (dev/staging/prod). Cada
/// entry point solo difiere en el [AppEnvironment] que le pasa a `bootstrap`
/// (básicamente, la `baseUrl` de la API); la app en sí es idéntica.
void bootstrap(AppEnvironment environment) {
  runApp(
    ProviderScope(
      overrides: [environmentProvider.overrideWithValue(environment)],
      child: const LavaderoApp(),
    ),
  );
}
