import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'lavadero_logo.dart';

/// Pantalla de espera de marca mientras se restaura la sesión al abrir (o
/// recargar) la app. Mejor que un blanco: confirma que la app está viva.
class LavaderoSplash extends StatelessWidget {
  const LavaderoSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: LavaderoGradients.deep),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LavaderoLogo(size: LavaderoSizes.logoXl, onDark: true),
              SizedBox(height: LavaderoSpacing.xl),
              SizedBox.square(
                dimension: LavaderoSizes.iconLg,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: LavaderoColors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
