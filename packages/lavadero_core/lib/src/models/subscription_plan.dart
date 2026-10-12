/// Un plan de suscripción del catálogo de la plataforma
/// (`/api/v1/plataforma/planes`, solo SUPER_ADMIN).
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.moneda,
    required this.maxSucursales,
    required this.maxEmpleados,
    required this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      SubscriptionPlan(
        id: json['id'] as String,
        nombre: json['nombre'] as String,
        precio: (json['precio'] as num).toDouble(),
        moneda: json['moneda'] as String,
        maxSucursales: json['maxSucursales'] as int,
        maxEmpleados: json['maxEmpleados'] as int,
        features: (json['features'] as List<dynamic>? ?? [])
            .map((f) => f as String)
            .toList(),
      );

  final String id;
  final String nombre;
  final double precio;
  final String moneda;
  final int maxSucursales;
  final int maxEmpleados;
  final List<String> features;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          other.id == id &&
          other.nombre == nombre &&
          other.precio == precio &&
          other.moneda == moneda &&
          other.maxSucursales == maxSucursales &&
          other.maxEmpleados == maxEmpleados &&
          _sameFeatures(other.features);

  bool _sameFeatures(List<String> other) {
    if (other.length != features.length) return false;
    for (var i = 0; i < features.length; i++) {
      if (other[i] != features[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nombre,
        precio,
        moneda,
        maxSucursales,
        maxEmpleados,
        Object.hashAll(features),
      );

  @override
  String toString() => 'SubscriptionPlan(id: $id, nombre: $nombre, precio: $precio $moneda)';
}
