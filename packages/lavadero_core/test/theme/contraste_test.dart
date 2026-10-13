import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

double _contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Texto blanco y secundario sobre los degradados que llevan texto debe pasar
/// WCAG AA (4.5:1) en cada parada del degradado.
void main() {
  for (final entrada in {
    'deep': LavaderoGradients.deep,
    'brandStrong': LavaderoGradients.brandStrong,
  }.entries) {
    for (final color in entrada.value.colors) {
      test('${entrada.key}: blanco y onBrandMuted ≥ 4.5:1 sobre $color', () {
        expect(_contraste(LavaderoColors.white, color), greaterThanOrEqualTo(4.5));
        expect(_contraste(LavaderoColors.onBrandMuted, color), greaterThanOrEqualTo(4.5));
      });
    }
  }
}
