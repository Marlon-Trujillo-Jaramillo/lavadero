import 'package:flutter/material.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../shared/widgets/profile_menu_button.dart';

/// Placeholder de navegación — lógica de negocio pendiente (fase posterior).
class VehiclesScreen extends StatelessWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        bottom: false,
        child: ComingSoonPlaceholder(
          header: PageHeader(
            title: 'Mis vehículos',
            trailing: ProfileMenuButton(),
          ),
          padding: EdgeInsets.fromLTRB(
            LavaderoSpacing.lg,
            LavaderoSpacing.md,
            LavaderoSpacing.lg,
            LavaderoSpacing.xl,
          ),
          icon: Icons.directions_car_rounded,
          headline: 'Tu garaje,\nmuy pronto.',
          message:
              'Guarda tus autos una vez y reserva sin volver a escribir placa ni '
              'modelo. Estamos terminando los últimos detalles.',
          features: [
            ComingSoonFeature(
              icon: Icons.garage_outlined,
              title: 'Todos tus autos en un lugar',
              message: 'Placa, modelo y color, listos para cada reserva.',
            ),
            ComingSoonFeature(
              icon: Icons.bolt_rounded,
              title: 'Reserva en un toque',
              message:
                  'Elige el auto y el servicio; nosotros hacemos el resto.',
            ),
            ComingSoonFeature(
              icon: Icons.history_rounded,
              title: 'Historial por vehículo',
              message:
                  'Cada lavado registrado, para saber cuándo toca el próximo.',
            ),
          ],
        ),
      ),
    );
  }
}
