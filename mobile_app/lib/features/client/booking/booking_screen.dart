import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/booking_controller.dart';

/// Formato simple `dd/MM/yyyy HH:mm`, sin depender del paquete `intl` (no es una dependencia del
/// proyecto — ver pubspec.yaml).
String _formatearFechaHora(DateTime fechaHora) {
  String dosDigitos(int n) => n.toString().padLeft(2, '0');
  return '${dosDigitos(fechaHora.day)}/${dosDigitos(fechaHora.month)}/${fechaHora.year} '
      '${dosDigitos(fechaHora.hour)}:${dosDigitos(fechaHora.minute)}';
}

/// Reserva de un servicio del catálogo, en una sucursal, para un horario. Consume
/// `/api/v1/agenda/reservas` (vía `SchedulingRepository`) y el catálogo de servicios activos.
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  ServiceItem? _servicioSeleccionado;
  Sucursal? _sucursalSeleccionada;
  DateTime? _fechaHoraSeleccionada;

  Future<void> _elegirFechaHora() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora,
      lastDate: ahora.add(const Duration(days: 60)),
    );
    if (fecha == null || !mounted) return;
    final hora = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(ahora));
    if (hora == null || !mounted) return;
    setState(() {
      _fechaHoraSeleccionada = DateTime(fecha.year, fecha.month, fecha.day, hora.hour, hora.minute);
    });
  }

  void _confirmar() {
    final servicio = _servicioSeleccionado;
    final sucursal = _sucursalSeleccionada;
    final fechaHora = _fechaHoraSeleccionada;
    if (servicio == null || sucursal == null || fechaHora == null) return;
    ref.read(bookingControllerProvider.notifier).reservar(
          sucursalId: sucursal.id,
          servicioId: servicio.id,
          fechaHoraInicio: fechaHora,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Reservar')),
      body: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: _buildBody(state, controller),
      ),
    );
  }

  Widget _buildBody(BookingState state, BookingController controller) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.reservaCreada != null) {
      return _ConfirmacionReserva(reserva: state.reservaCreada!, onReservarOtra: controller.reiniciar);
    }

    // Si solo hay una sucursal, se elige automáticamente y no se muestra el selector.
    if (_sucursalSeleccionada == null && state.sucursales.length == 1) {
      _sucursalSeleccionada = state.sucursales.first;
    }

    return ListView(
      children: [
        if (state.errorMessage != null) ...[
          ErrorBanner(message: state.errorMessage!),
          const SizedBox(height: LavaderoSpacing.md),
        ],
        if (state.servicios.isEmpty)
          const Text('Este lavadero todavía no publicó servicios para reservar.')
        else ...[
          DropdownButtonFormField<ServiceItem>(
            initialValue: _servicioSeleccionado,
            decoration: const InputDecoration(labelText: 'Servicio'),
            items: [
              for (final servicio in state.servicios)
                DropdownMenuItem(
                  value: servicio,
                  child: Text('${servicio.nombre} · \$${servicio.precio.toStringAsFixed(0)}'),
                ),
            ],
            onChanged: (servicio) => setState(() => _servicioSeleccionado = servicio),
          ),
          const SizedBox(height: LavaderoSpacing.md),
          if (state.sucursales.length > 1)
            DropdownButtonFormField<Sucursal>(
              initialValue: _sucursalSeleccionada,
              decoration: const InputDecoration(labelText: 'Sucursal'),
              items: [
                for (final sucursal in state.sucursales)
                  DropdownMenuItem(value: sucursal, child: Text(sucursal.nombre)),
              ],
              onChanged: (sucursal) => setState(() => _sucursalSeleccionada = sucursal),
            ),
          const SizedBox(height: LavaderoSpacing.md),
          OutlinedButton.icon(
            onPressed: _elegirFechaHora,
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(
              _fechaHoraSeleccionada == null
                  ? 'Elegir fecha y hora'
                  : _formatearFechaHora(_fechaHoraSeleccionada!),
            ),
          ),
          const SizedBox(height: LavaderoSpacing.lg),
          LoadingButton(
            isLoading: state.isSubmitting,
            onPressed: _servicioSeleccionado != null &&
                    _sucursalSeleccionada != null &&
                    _fechaHoraSeleccionada != null
                ? _confirmar
                : null,
            child: const Text('Confirmar reserva'),
          ),
        ],
      ],
    );
  }
}

class _ConfirmacionReserva extends StatelessWidget {
  const _ConfirmacionReserva({required this.reserva, required this.onReservarOtra});

  final Reserva reserva;
  final VoidCallback onReservarOtra;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: LavaderoSpacing.md),
          const Text('¡Reserva confirmada!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: LavaderoSpacing.sm),
          Text(_formatearFechaHora(reserva.fechaHoraInicio.toLocal())),
          const SizedBox(height: LavaderoSpacing.lg),
          OutlinedButton(onPressed: onReservarOtra, child: const Text('Reservar otra')),
        ],
      ),
    );
  }
}
