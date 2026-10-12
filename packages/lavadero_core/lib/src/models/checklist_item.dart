/// Un ítem del checklist de servicio de una reserva (`/api/v1/agenda/reservas/{id}/checklist`).
class ChecklistItem {
  const ChecklistItem({
    required this.tipo,
    required this.label,
    required this.completado,
    this.completadoEn,
  });

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
        tipo: json['tipo'] as String,
        label: json['label'] as String,
        completado: json['completado'] as bool,
        completadoEn: json['completadoEn'] == null
            ? null
            : DateTime.parse(json['completadoEn'] as String),
      );

  final String tipo;
  final String label;
  final bool completado;
  final DateTime? completadoEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          other.tipo == tipo &&
          other.label == label &&
          other.completado == completado &&
          other.completadoEn == completadoEn;

  @override
  int get hashCode => Object.hash(tipo, label, completado, completadoEn);

  @override
  String toString() => 'ChecklistItem(tipo: $tipo, completado: $completado)';
}
