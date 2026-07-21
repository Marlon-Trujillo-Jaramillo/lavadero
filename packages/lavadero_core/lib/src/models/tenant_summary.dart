/// Resultado de `GET /api/v1/tenants?query=`.
class TenantSummary {
  const TenantSummary({
    required this.id,
    required this.slug,
    required this.nombre,
  });

  factory TenantSummary.fromJson(Map<String, dynamic> json) => TenantSummary(
        id: json['id'] as String,
        slug: json['slug'] as String,
        nombre: json['nombre'] as String,
      );

  final String id;
  final String slug;
  final String nombre;

  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'nombre': nombre};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TenantSummary &&
          other.id == id &&
          other.slug == slug &&
          other.nombre == nombre;

  @override
  int get hashCode => Object.hash(id, slug, nombre);

  @override
  String toString() => 'TenantSummary(id: $id, slug: $slug, nombre: $nombre)';
}
