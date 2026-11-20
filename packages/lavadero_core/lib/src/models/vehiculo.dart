import 'tipo_vehiculo.dart';

/// Un vehículo de "Mis vehículos" (`/api/v1/vehiculos`). La placa ya viene
/// normalizada por el backend (ABC123).
class Vehiculo {
  const Vehiculo({
    required this.id,
    required this.placa,
    required this.tipo,
    this.marca,
    this.color,
    required this.creadoEn,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
        id: json['id'] as String,
        placa: json['placa'] as String,
        tipo: TipoVehiculo.fromWireValue(json['tipo'] as String),
        marca: json['marca'] as String?,
        color: json['color'] as String?,
        creadoEn: DateTime.parse(json['creadoEn'] as String),
      );

  final String id;
  final String placa;
  final TipoVehiculo tipo;
  final String? marca;
  final String? color;
  final DateTime creadoEn;

  /// "Camioneta · Mazda · Rojo" (omite lo que no se registró).
  String get descripcion => [
        tipo.label,
        if (marca != null) marca!,
        if (color != null) color!,
      ].join(' · ');

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehiculo &&
          other.id == id &&
          other.placa == placa &&
          other.tipo == tipo &&
          other.marca == marca &&
          other.color == color &&
          other.creadoEn == creadoEn;

  @override
  int get hashCode => Object.hash(id, placa, tipo, marca, color, creadoEn);

  @override
  String toString() => 'Vehiculo(placa: $placa, tipo: $tipo)';
}
