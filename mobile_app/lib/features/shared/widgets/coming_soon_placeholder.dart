import 'package:flutter/material.dart';

/// Placeholder de navegación para features de negocio que aún no se implementan. Único uso
/// restante: `client/vehicles` (ver docs/specs/006-checklist-incidencias.md — checklist/incidencias
/// de empleado ya se implementaron y dejaron de usar este placeholder).
class ComingSoonPlaceholder extends StatelessWidget {
  const ComingSoonPlaceholder({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              'Próximamente',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
