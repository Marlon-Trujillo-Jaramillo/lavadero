import 'reserva_estado.dart';

/// Una reserva (`/api/v1/agenda/reservas`). Precio/duración vienen ya congelados desde el backend
/// al momento de la reserva — ver `docs/specs/002-agenda-reservas.md`.
class Reserva {
  const Reserva({
    required this.id,
    required this.sucursalId,
    required this.servicioId,
    required this.clienteId,
    required this.fechaHoraInicio,
    required this.fechaHoraFin,
    required this.duracionEstimadaMinutos,
    required this.precio,
    required this.moneda,
    required this.estado,
    this.vehiculoId,
    this.vehiculoPlaca,
  });

  factory Reserva.fromJson(Map<String, dynamic> json) => Reserva(
    id: json['id'] as String,
    sucursalId: json['sucursalId'] as String,
    servicioId: json['servicioId'] as String,
    clienteId: json['clienteId'] as String,
    fechaHoraInicio: DateTime.parse(json['fechaHoraInicio'] as String),
    fechaHoraFin: DateTime.parse(json['fechaHoraFin'] as String),
    duracionEstimadaMinutos: json['duracionEstimadaMinutos'] as int,
    precio: (json['precio'] as num).toDouble(),
    moneda: json['moneda'] as String,
    estado: ReservaEstado.fromWireValue(json['estado'] as String),
    vehiculoId: json['vehiculoId'] as String?,
    vehiculoPlaca: json['vehiculoPlaca'] as String?,
  );

  final String id;
  final String sucursalId;
  final String servicioId;
  final String clienteId;
  final DateTime fechaHoraInicio;
  final DateTime fechaHoraFin;
  final int duracionEstimadaMinutos;
  final double precio;
  final String moneda;
  final ReservaEstado estado;

  /// Vehículo elegido al reservar (opcional) y su placa congelada en ese momento.
  final String? vehiculoId;
  final String? vehiculoPlaca;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Reserva &&
          other.id == id &&
          other.sucursalId == sucursalId &&
          other.servicioId == servicioId &&
          other.clienteId == clienteId &&
          other.fechaHoraInicio == fechaHoraInicio &&
          other.fechaHoraFin == fechaHoraFin &&
          other.duracionEstimadaMinutos == duracionEstimadaMinutos &&
          other.precio == precio &&
          other.moneda == moneda &&
          other.estado == estado &&
          other.vehiculoId == vehiculoId &&
          other.vehiculoPlaca == vehiculoPlaca;

  @override
  int get hashCode => Object.hash(
    id,
    sucursalId,
    servicioId,
    clienteId,
    fechaHoraInicio,
    fechaHoraFin,
    duracionEstimadaMinutos,
    precio,
    moneda,
    estado,
    vehiculoId,
    vehiculoPlaca,
  );

  @override
  String toString() =>
      'Reserva(id: $id, fechaHoraInicio: $fechaHoraInicio, estado: $estado)';
}
