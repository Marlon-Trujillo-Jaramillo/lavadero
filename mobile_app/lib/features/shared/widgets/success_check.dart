import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

/// Check de éxito animado: el círculo con el degradado de marca crece con
/// un leve rebote y el visto se "dibuja" encima. Solo animaciones
/// implícitas (`TweenAnimationBuilder`), sin paquetes.
class SuccessCheck extends StatelessWidget {
  const SuccessCheck({super.key, this.size = LavaderoSizes.avatarLg * 2});

  final double size;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
      duration: LavaderoMotion.slow * 2,
      curve: Curves.linear,
      builder: (context, t, _) {
        final grow = Curves.easeOutBack.transform((t / 0.55).clamp(0, 1));
        final draw = LavaderoMotion.emphasized.transform(
          ((t - 0.45) / 0.55).clamp(0, 1),
        );
        final halo = math.sin(t * math.pi);
        return SizedBox.square(
          dimension: size * 1.5,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Halo que se expande y se desvanece.
              Container(
                width: size * (1 + 0.5 * t),
                height: size * (1 + 0.5 * t),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LavaderoColors.aqua.withValues(alpha: 0.18 * halo),
                ),
              ),
              Transform.scale(
                scale: grow,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LavaderoGradients.brandStrong,
                    boxShadow: LavaderoShadows.glow(LavaderoColors.ocean),
                  ),
                  child: CustomPaint(painter: _CheckPainter(progress: draw)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final w = size.width;
    final path = Path()
      ..moveTo(w * 0.29, w * 0.52)
      ..lineTo(w * 0.44, w * 0.66)
      ..lineTo(w * 0.72, w * 0.37);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = LavaderoColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
