import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// Avatar circular con iniciales y un color estable derivado del nombre
/// (la misma persona siempre tiene el mismo color).
class AvatarInitials extends StatelessWidget {
  const AvatarInitials({
    super.key,
    required this.name,
    this.size = LavaderoSizes.avatarMd,
  });

  final String name;
  final double size;

  static const _palette = [
    LavaderoColors.ocean,
    LavaderoColors.aqua,
    LavaderoColors.success,
    LavaderoColors.warning,
    LavaderoColors.info,
    LavaderoColors.oceanDeep,
  ];

  String get _initials {
    final parts = name
        .split(RegExp(r'[\s@._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts[1].characters.first : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _palette[name.hashCode.abs() % _palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.14),
      ),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
