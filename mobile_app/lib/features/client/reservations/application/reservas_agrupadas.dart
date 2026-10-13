import 'package:lavadero_core/lavadero_core.dart';

import 'my_reservations_controller.dart';

/// Agrupación de "Mis reservas" para la UI (inicio y lista). Una reserva es
/// "próxima" si sigue activa (pendiente o en progreso) y todavía no
/// terminó; todo lo demás es historial.
extension ReservasAgrupadas on MyReservationsState {
  bool _esProxima(Reserva r, DateTime ahora) =>
      (r.estado == ReservaEstado.pendiente ||
          r.estado == ReservaEstado.enProgreso) &&
      r.fechaHoraFin.isAfter(ahora);

  /// Activas, la más cercana primero.
  List<Reserva> proximas(DateTime ahora) =>
      reservas.where((r) => _esProxima(r, ahora)).toList()
        ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));

  /// Historial, la más reciente primero (orden que ya trae el controller).
  List<Reserva> anteriores(DateTime ahora) =>
      reservas.where((r) => !_esProxima(r, ahora)).toList();

  /// La reserva a destacar en el inicio, si hay alguna.
  Reserva? proxima(DateTime ahora) {
    final lista = proximas(ahora);
    return lista.isEmpty ? null : lista.first;
  }
}
