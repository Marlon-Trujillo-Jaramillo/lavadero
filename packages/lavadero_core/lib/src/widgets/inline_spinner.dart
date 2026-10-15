import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Spinner chico para estados de carga EN LÍNEA (dentro de un botón, en lugar
/// de un switch o de las acciones de una fila). Para una pantalla entera usar
/// `Skeleton`/`SkeletonList`, no esto.
class InlineSpinner extends StatelessWidget {
  const InlineSpinner({
    super.key,
    this.size = LavaderoSizes.iconMd,
    this.color,
  });

  final double size;

  /// Por defecto, el color primario del tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: LavaderoSizes.spinnerStroke,
        color: color,
      ),
    );
  }
}
