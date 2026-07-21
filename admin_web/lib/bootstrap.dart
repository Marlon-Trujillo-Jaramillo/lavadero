import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/di/environment.dart';
import 'app/di/providers.dart';

void bootstrap(AppEnvironment environment) {
  runApp(
    ProviderScope(
      overrides: [environmentProvider.overrideWithValue(environment)],
      child: const AdminWebApp(),
    ),
  );
}
