/// Un servicio del catálogo (`GET/POST /api/v1/catalogo/servicios`).
class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.duracionEstimadaMinutos,
    required this.precio,
    required this.moneda,
    required this.activo,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        descripcion: json['descripcion'] as String?,
        duracionEstimadaMinutos: json['duracionEstimadaMinutos'] as int,
        precio: (json['precio'] as num).toDouble(),
        moneda: json['moneda'] as String,
        activo: json['activo'] as bool,
      );

  final String id;
  final String nombre;
  final String? descripcion;
  final int duracionEstimadaMinutos;
  final double precio;
  final String moneda;
  final bool activo;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'duracionEstimadaMinutos': duracionEstimadaMinutos,
        'precio': precio,
        'moneda': moneda,
        'activo': activo,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceItem &&
          other.id == id &&
          other.nombre == nombre &&
          other.descripcion == descripcion &&
          other.duracionEstimadaMinutos == duracionEstimadaMinutos &&
          other.precio == precio &&
          other.moneda == moneda &&
          other.activo == activo;

  @override
  int get hashCode => Object.hash(
        id,
        nombre,
        descripcion,
        duracionEstimadaMinutos,
        precio,
        moneda,
        activo,
      );

  @override
  String toString() =>
      'ServiceItem(id: $id, nombre: $nombre, precio: $precio $moneda, activo: $activo)';
}
