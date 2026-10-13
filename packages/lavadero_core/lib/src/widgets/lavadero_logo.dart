import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Marca de Lavadero: una gota con degradado océano→turquesa y un brillo,
/// dibujada en código (nítida a cualquier tamaño, sin assets). Con
/// [showWordmark] agrega el nombre al lado.
class LavaderoLogo extends StatelessWidget {
  const LavaderoLogo({
    super.key,
    this.size = 36,
    this.showWordmark = false,
    this.onDark = false,
    this.label = 'Lavadero',
  });

  final double size;
  final bool showWordmark;

  /// Sobre fondos de marca/oscuros: wordmark en blanco.
  final bool onDark;
  final String label;

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _DropPainter(onDark: onDark)),
    );
    if (!showWordmark) return mark;
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              fontSize: size * 0.62,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: onDark ? LavaderoColors.white : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _DropPainter extends CustomPainter {
  const _DropPainter({required this.onDark});

  final bool onDark;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Contenedor redondeado (squircle) con degradado de marca.
    final container = RRect.fromRectAndRadius(rect, Radius.circular(w * 0.3));
    final containerPaint = Paint()
      ..shader =
          (onDark
                  ? const LinearGradient(
                      colors: [
                        LavaderoColors.white,
                        LavaderoColors.aquaContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LavaderoGradients.brand)
              .createShader(rect);
    canvas.drawRRect(container, containerPaint);

    // Gota.
    final drop = Path()
      ..moveTo(w * 0.5, h * 0.18)
      ..cubicTo(w * 0.5, h * 0.18, w * 0.27, h * 0.46, w * 0.27, h * 0.6)
      ..cubicTo(w * 0.27, h * 0.73, w * 0.37, h * 0.83, w * 0.5, h * 0.83)
      ..cubicTo(w * 0.63, h * 0.83, w * 0.73, h * 0.73, w * 0.73, h * 0.6)
      ..cubicTo(w * 0.73, h * 0.46, w * 0.5, h * 0.18, w * 0.5, h * 0.18)
      ..close();
    canvas.drawPath(
      drop,
      Paint()..color = onDark ? LavaderoColors.ocean : LavaderoColors.white,
    );

    // Brillo.
    final shine = Path()
      ..addArc(
        Rect.fromCircle(center: Offset(w * 0.5, h * 0.6), radius: w * 0.14),
        2.4,
        1.1,
      );
    canvas.drawPath(
      shine,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w * 0.045
        ..color = (onDark ? LavaderoColors.white : LavaderoColors.aqua)
            .withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(_DropPainter oldDelegate) => oldDelegate.onDark != onDark;
}
