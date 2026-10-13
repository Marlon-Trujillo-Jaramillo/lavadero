import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Bloque gris con un brillo que recorre de izquierda a derecha: estado de
/// carga que anticipa la forma del contenido (mejor que un spinner suelto).
///
/// Dentro de un [SkeletonScope] todos los bloques comparten UN solo ticker
/// (y el brillo va sincronizado); fuera de uno, cada bloque anima por su
/// cuenta. Con "reducir movimiento" del sistema
/// (`MediaQuery.disableAnimations`) el bloque queda estático.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height = LavaderoSpacing.md,
    this.radius = LavaderoRadii.sm,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

// `TickerProviderStateMixin` (no el Single): el ticker propio se crea y
// descarta si el bloque entra/sale de un `SkeletonScope` o cambia
// "reducir movimiento".
class _SkeletonState extends State<Skeleton> with TickerProviderStateMixin {
  AnimationController? _propio;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final necesitaPropio =
        SkeletonScope._of(context) == null &&
        !MediaQuery.disableAnimationsOf(context);
    if (necesitaPropio && _propio == null) {
      _propio = AnimationController(
        vsync: this,
        duration: LavaderoMotion.shimmer,
      )..repeat();
    } else if (!necesitaPropio && _propio != null) {
      _propio!.dispose();
      _propio = null;
    }
  }

  @override
  void dispose() {
    _propio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final animacion = MediaQuery.disableAnimationsOf(context)
        ? null
        : (SkeletonScope._of(context) ?? _propio);
    if (animacion == null) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    final highlight = scheme.surfaceContainerLow;
    return AnimatedBuilder(
      animation: animacion,
      builder: (context, _) {
        final t = animacion.value * 3 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}

/// Un solo ticker para todos los [Skeleton] de su subárbol (una pantalla de
/// carga con 10 bloques ya no crea 10 animaciones). Se detiene con
/// "reducir movimiento".
class SkeletonScope extends StatefulWidget {
  const SkeletonScope({super.key, required this.child});

  final Widget child;

  static Animation<double>? _of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_SkeletonAnimation>()
      ?.animation;

  @override
  State<SkeletonScope> createState() => _SkeletonScopeState();
}

class _SkeletonScopeState extends State<SkeletonScope>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: LavaderoMotion.shimmer,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _SkeletonAnimation(animation: _controller, child: widget.child);
}

class _SkeletonAnimation extends InheritedWidget {
  const _SkeletonAnimation({required this.animation, required super.child});

  final Animation<double> animation;

  @override
  bool updateShouldNotify(_SkeletonAnimation oldWidget) =>
      animation != oldWidget.animation;
}

/// Filas esqueleto (ícono + dos líneas) para pantallas de lista. Por
/// defecto es un `ListView` que ocupa el alto disponible; [SkeletonList.inline]
/// las pone en una `Column` para usarlas DENTRO de un scroll que ya existe
/// (un `ListView` anidado sin `shrinkWrap` rompe con altura no acotada).
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.itemCount = 6, this.padding})
    : _inline = false;

  const SkeletonList.inline({super.key, this.itemCount = 3})
    : padding = null,
      _inline = true;

  final int itemCount;
  final EdgeInsetsGeometry? padding;
  final bool _inline;

  @override
  Widget build(BuildContext context) {
    if (_inline) {
      return SkeletonScope(
        child: Column(
          children: [
            for (var i = 0; i < itemCount; i++) ...[
              if (i > 0) const SizedBox(height: LavaderoSpacing.sm),
              const _SkeletonRow(),
            ],
          ],
        ),
      );
    }
    return SkeletonScope(
      child: ListView.separated(
        padding: padding ?? const EdgeInsets.all(LavaderoSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: LavaderoSpacing.sm),
        itemBuilder: (context, index) => const _SkeletonRow(),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(LavaderoSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(LavaderoRadii.lg),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: const Row(
        children: [
          Skeleton(
            width: LavaderoSizes.avatarMd,
            height: LavaderoSizes.avatarMd,
            radius: LavaderoRadii.md,
          ),
          SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FractionallySizedBox(widthFactor: 0.6, child: Skeleton()),
                SizedBox(height: LavaderoSpacing.sm),
                FractionallySizedBox(
                  widthFactor: 0.35,
                  child: Skeleton(height: LavaderoSpacing.smd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
