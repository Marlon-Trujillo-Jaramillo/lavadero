/// Un miembro del staff del tenant actual (rol EMPLEADO), `/api/v1/empleados`.
class Empleado {
  const Empleado({
    required this.id,
    required this.email,
    required this.nombre,
    this.sucursalId,
    required this.estado,
  });

  factory Empleado.fromJson(Map<String, dynamic> json) => Empleado(
        id: json['id'] as String,
        email: json['email'] as String,
        nombre: json['nombre'] as String,
        sucursalId: json['sucursalId'] as String?,
        estado: json['estado'] as String,
      );

  final String id;
  final String email;
  final String nombre;
  final String? sucursalId;
  final String estado;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Empleado &&
          other.id == id &&
          other.email == email &&
          other.nombre == nombre &&
          other.sucursalId == sucursalId &&
          other.estado == estado;

  @override
  int get hashCode => Object.hash(id, email, nombre, sucursalId, estado);

  @override
  String toString() => 'Empleado(id: $id, email: $email, nombre: $nombre)';
}
