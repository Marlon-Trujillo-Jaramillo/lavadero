/// Una sucursal del tenant actual (`GET /api/v1/sucursales`).
class Sucursal {
  const Sucursal({
    required this.id,
    required this.nombre,
    this.direccion,
    required this.capacidadSimultanea,
  });

  factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        direccion: json['direccion'] as String?,
        capacidadSimultanea: json['capacidadSimultanea'] as int,
      );

  final String id;
  final String nombre;
  final String? direccion;
  final int capacidadSimultanea;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sucursal &&
          other.id == id &&
          other.nombre == nombre &&
          other.direccion == direccion &&
          other.capacidadSimultanea == capacidadSimultanea;

  @override
  int get hashCode => Object.hash(id, nombre, direccion, capacidadSimultanea);

  @override
  String toString() => 'Sucursal(id: $id, nombre: $nombre)';
}
