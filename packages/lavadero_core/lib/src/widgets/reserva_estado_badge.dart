import 'package:flutter/material.dart';

import '../models/reserva_estado.dart';
import '../theme/design_tokens.dart';
import 'status_badge.dart';

/// Etiqueta y color de cada [ReservaEstado], en un solo sitio para que la
/// agenda del admin y las vistas de la app móvil no diverjan.
extension ReservaEstadoVisual on ReservaEstado {
  String get etiqueta => switch (this) {
    ReservaEstado.pendiente => 'Pendiente',
    ReservaEstado.enProgreso => 'En progreso',
    ReservaEstado.completada => 'Completada',
    ReservaEstado.cancelada => 'Cancelada',
  };

  Color colorDe(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return switch (this) {
      ReservaEstado.pendiente => LavaderoColors.warning,
      ReservaEstado.enProgreso => scheme.primary,
      ReservaEstado.completada => LavaderoColors.success,
      ReservaEstado.cancelada => scheme.outline,
    };
  }
}

/// [StatusBadge] ya resuelto para el estado de una reserva.
class ReservaEstadoBadge extends StatelessWidget {
  const ReservaEstadoBadge({super.key, required this.estado});

  final ReservaEstado estado;

  @override
  Widget build(BuildContext context) {
    return StatusBadge(label: estado.etiqueta, color: estado.colorDe(context));
  }
}
