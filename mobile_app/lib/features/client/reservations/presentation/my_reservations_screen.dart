import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../application/my_reservations_controller.dart';

/// Formato simple `dd/MM/yyyy HH:mm`, sin depender del paquete `intl` (no es una dependencia del
/// proyecto — mismo patrón que `booking_screen.dart`).
String _formatearFechaHora(DateTime fechaHora) {
  String dosDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dosDigitos(fechaHora.day)}/${dosDigitos(fechaHora.month)}/${fechaHora.year} '
      '${dosDigitos(fechaHora.hour)}:${dosDigitos(fechaHora.minute)}';
}

(String, Color) _estadoInfo(BuildContext context, ReservaEstado estado) {
  final scheme = Theme.of(context).colorScheme;
  return switch (estado) {
    ReservaEstado.pendiente => ('Pendiente', LavaderoColors.warning),
    ReservaEstado.enProgreso => ('En progreso', scheme.primary),
    ReservaEstado.completada => ('Completada', LavaderoColors.success),
    ReservaEstado.cancelada => ('Cancelada', scheme.outline),
  };
}

/// Historial de reservas del cliente autenticado (`GET /agenda/reservas/mias`), con opción de
/// cancelar mientras siga en estado PENDIENTE (única transición válida — ver `Reserva.java`).
class MyReservationsScreen extends ConsumerWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myReservationsControllerProvider);
    final controller = ref.read(myReservationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis reservas')),
      body: RefreshIndicator(
        onRefresh: controller.cargar,
        child: _buildBody(context, state, controller),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    MyReservationsState state,
    MyReservationsController controller,
  ) {
    if (state.isLoading && state.reservas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.reservas.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (state.errorMessage != null) ...[
            Padding(
              padding: const EdgeInsets.all(LavaderoSpacing.md),
              child: ErrorBanner(message: state.errorMessage!),
            ),
          ],
          const SizedBox(height: LavaderoSpacing.xxl),
          const EmptyState(
            icon: Icons.calendar_month_outlined,
            title: 'Todavía no tenés reservas',
            message: 'Cuando reserves un lavado, lo vas a ver acá.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(LavaderoSpacing.md),
      children: [
        if (state.errorMessage != null) ...[
          ErrorBanner(message: state.errorMessage!),
          const SizedBox(height: LavaderoSpacing.md),
        ],
        for (final reserva in state.reservas) ...[
          _ReservaCard(
            reserva: reserva,
            servicio: state.servicios[reserva.servicioId],
            cancelando: state.cancelandoId == reserva.id,
            onCancelar: reserva.estado == ReservaEstado.pendiente
                ? () => controller.cancelar(reserva.id)
                : null,
          ),
          const SizedBox(height: LavaderoSpacing.sm),
        ],
      ],
    );
  }
}

class _ReservaCard extends StatelessWidget {
  const _ReservaCard({
    required this.reserva,
    required this.servicio,
    required this.cancelando,
    required this.onCancelar,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final bool cancelando;
  final VoidCallback? onCancelar;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _estadoInfo(context, reserva.estado);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    servicio?.nombre ?? 'Servicio',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(label: label, color: color),
              ],
            ),
            const SizedBox(height: LavaderoSpacing.xs),
            Text(_formatearFechaHora(reserva.fechaHoraInicio.toLocal())),
            const SizedBox(height: LavaderoSpacing.xs),
            Text(
              '\$${reserva.precio.toStringAsFixed(0)} ${reserva.moneda}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (onCancelar != null) ...[
              const SizedBox(height: LavaderoSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: cancelando ? null : onCancelar,
                  child: cancelando
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Cancelar'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
