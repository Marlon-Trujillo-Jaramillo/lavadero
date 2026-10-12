import 'incidencia_categoria.dart';

/// Un problema reportado por un empleado (`/api/v1/incidencias`) — ver
/// docs/specs/006-checklist-incidencias.md.
class Incidencia {
  const Incidencia({
    required this.id,
    required this.sucursalId,
    this.reservaId,
    required this.categoria,
    required this.descripcion,
    required this.creadoEn,
  });

  factory Incidencia.fromJson(Map<String, dynamic> json) => Incidencia(
        id: json['id'] as String,
        sucursalId: json['sucursalId'] as String,
        reservaId: json['reservaId'] as String?,
        categoria: IncidenciaCategoria.fromWireValue(json['categoria'] as String),
        descripcion: json['descripcion'] as String,
        creadoEn: DateTime.parse(json['creadoEn'] as String),
      );

  final String id;
  final String sucursalId;
  final String? reservaId;
  final IncidenciaCategoria categoria;
  final String descripcion;
  final DateTime creadoEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Incidencia &&
          other.id == id &&
          other.sucursalId == sucursalId &&
          other.reservaId == reservaId &&
          other.categoria == categoria &&
          other.descripcion == descripcion &&
          other.creadoEn == creadoEn;

  @override
  int get hashCode =>
      Object.hash(id, sucursalId, reservaId, categoria, descripcion, creadoEn);

  @override
  String toString() => 'Incidencia(id: $id, categoria: $categoria)';
}
