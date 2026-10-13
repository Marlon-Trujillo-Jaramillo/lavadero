import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Entrada suave (fade + desplazamiento corto hacia arriba). Con [index] se
/// escalona en listas/grillas: cada elemento entra un poco después del
/// anterior, hasta un tope para que listas largas no tarden en aparecer.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 12,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  static const _maxStaggered = 8;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LavaderoMotion.slow,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: LavaderoMotion.emphasized,
  );

  Timer? _delay;

  @override
  void initState() {
    super.initState();
    final steps = widget.index.clamp(0, _maxStaggered);
    if (steps == 0) {
      _controller.forward();
    } else {
      // Timer cancelable (no Future.delayed): si el widget se desmonta antes,
      // no queda un callback colgando.
      _delay = Timer(LavaderoMotion.stagger * steps, _controller.forward);
    }
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _curve,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _curve.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - _curve.value)),
          child: child,
        ),
      ),
    );
  }
}
