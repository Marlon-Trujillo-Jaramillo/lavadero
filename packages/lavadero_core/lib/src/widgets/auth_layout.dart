import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'fade_slide_in.dart';
import 'lavadero_logo.dart';

/// Esqueleto de las pantallas de acceso (login, registro, selección de
/// lavadero). En ancho (web/tablet): panel de marca con degradado a la
/// izquierda y el formulario a la derecha. En móvil: cabecera de marca con
/// degradado y el formulario en una hoja que sube encima.
class AuthLayout extends StatelessWidget {
  const AuthLayout({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.brandHeadline = 'Tu lavadero,\nimpecable.',
    this.brandMessage =
        'Reservas, agenda y equipo en un solo lugar. Sin filas, sin papel.',
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final String brandHeadline;
  final String brandMessage;

  /// Botón de volver u otro control arriba del formulario.
  final Widget? leading;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= LavaderoBreakpoints.authWide) {
            return Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _BrandPanel(
                    headline: brandHeadline,
                    message: brandMessage,
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(LavaderoSpacing.xxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: LavaderoSizes.formMaxWidth,
                        ),
                        child: _FormColumn(
                          title: title,
                          subtitle: subtitle,
                          leading: leading,
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return _CompactLayout(
            title: title,
            subtitle: subtitle,
            leading: leading,
            child: child,
          );
        },
      ),
    );
  }
}

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[
            Align(alignment: Alignment.centerLeft, child: leading),
            const SizedBox(height: LavaderoSpacing.md),
          ],
          Text(title, style: theme.textTheme.headlineMedium),
          if (subtitle != null) ...[
            const SizedBox(height: LavaderoSpacing.sm),
            Text(
              subtitle!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: LavaderoSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({required this.headline, required this.message});

  final String headline;
  final String message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: LavaderoGradients.deep),
      child: Stack(
        children: [
          const Positioned.fill(child: _Bubbles()),
          Padding(
            padding: const EdgeInsets.all(LavaderoSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const LavaderoLogo(
                  size: LavaderoSizes.logoMd,
                  showWordmark: true,
                  onDark: true,
                ),
                const Spacer(),
                Text(
                  headline,
                  style: textTheme.displaySmall?.copyWith(
                    color: LavaderoColors.white,
                  ),
                ),
                const SizedBox(height: LavaderoSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: LavaderoSizes.formMaxWidth,
                  ),
                  child: Text(
                    message,
                    style: textTheme.bodyLarge?.copyWith(
                      color: LavaderoColors.onBrandMuted,
                    ),
                  ),
                ),
                const SizedBox(height: LavaderoSpacing.xxl),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLayout extends StatelessWidget {
  const _CompactLayout({
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final topInset = MediaQuery.paddingOf(context).top;
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: LavaderoGradients.deep),
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: LavaderoSizes.authHeaderHeight + topInset,
                child: Stack(
                  children: [
                    const Positioned.fill(child: _Bubbles()),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        LavaderoSpacing.lg,
                        topInset + LavaderoSpacing.lg,
                        LavaderoSpacing.lg,
                        LavaderoSpacing.lg,
                      ),
                      child: const Align(
                        alignment: Alignment.bottomLeft,
                        child: LavaderoLogo(
                          size: LavaderoSizes.logoMd + LavaderoSpacing.xs,
                          showWordmark: true,
                          onDark: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.sizeOf(context).height -
                      LavaderoSizes.authHeaderHeight -
                      topInset,
                ),
                padding: const EdgeInsets.fromLTRB(
                  LavaderoSpacing.lg,
                  LavaderoSpacing.xl,
                  LavaderoSpacing.lg,
                  LavaderoSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(LavaderoRadii.xl),
                  ),
                ),
                child: _FormColumn(
                  title: title,
                  subtitle: subtitle,
                  leading: leading,
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Burbujas translúcidas decorativas sobre el degradado de marca.
class _Bubbles extends StatelessWidget {
  const _Bubbles();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(child: CustomPaint(painter: _BubblesPainter()));
  }
}

class _BubblesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = LavaderoColors.white.withValues(alpha: 0.07);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = LavaderoColors.white.withValues(alpha: 0.12);
    final w = size.width;
    final h = size.height;
    canvas
      ..drawCircle(Offset(w * 0.86, h * 0.14), w * 0.22, paint)
      ..drawCircle(Offset(w * 0.12, h * 0.9), w * 0.3, paint)
      ..drawCircle(Offset(w * 0.7, h * 0.62), w * 0.06, paint)
      ..drawCircle(Offset(w * 0.86, h * 0.14), w * 0.3, ring)
      ..drawCircle(Offset(w * 0.32, h * 0.3), w * 0.035, ring);
  }

  @override
  bool shouldRepaint(_BubblesPainter oldDelegate) => false;
}
