import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Envuelve un widget tocable con una leve escala al presionar (y al pasar
/// el mouse en web). Da sensación física sin depender del ripple de
/// Material, que sobre tarjetas con sombra se ve plano.
///
/// Accesible: se anuncia como botón, entra en el orden de foco (Tab), se
/// activa con Enter/Espacio y muestra un anillo de foco visible cuando se
/// llega con teclado. Sin [onTap] queda deshabilitado (sin hover ni foco).
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.pressedScale = 0.98,
    this.semanticLabel,
    this.selected,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double pressedScale;

  /// Etiqueta para lectores de pantalla si el contenido no la da por sí solo.
  final String? semanticLabel;

  /// Para opciones seleccionables (chips, días...): se anuncia el estado.
  final bool? selected;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onTap != null;

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activar() => widget.onTap?.call();

  @override
  Widget build(BuildContext context) {
    final scale = _pressed
        ? widget.pressedScale
        : (_hovered && _enabled ? 1.01 : 1.0);
    final radius = widget.borderRadius ?? BorderRadius.circular(LavaderoRadii.lg);
    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: _enabled,
        mouseCursor: _enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowHoverHighlight: (value) {
          if (_hovered != value) setState(() => _hovered = value);
        },
        onShowFocusHighlight: (value) {
          if (_focused != value) setState(() => _focused = value);
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _activar(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => _activar(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: scale,
            duration: LavaderoMotion.fast,
            curve: LavaderoMotion.emphasized,
            child: FocusRing(
              visible: _focused,
              borderRadius: radius,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Anillo de foco de teclado (2px del color primario) dibujado ENCIMA del
/// contenido, para controles propios que no usan los botones de Material.
class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.visible,
    required this.child,
    this.borderRadius,
  });

  final bool visible;
  final Widget child;
  final BorderRadius? borderRadius;

  static const double _grosor = 2;

  @override
  Widget build(BuildContext context) {
    if (!visible) return child;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: _grosor,
        ),
      ),
      child: child,
    );
  }
}
