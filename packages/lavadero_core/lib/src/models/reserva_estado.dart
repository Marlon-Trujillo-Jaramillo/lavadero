/// Estado de una reserva, tal como lo expone el backend en `reserva.estado`.
enum ReservaEstado {
  pendiente('PENDIENTE'),
  enProgreso('EN_PROGRESO'),
  completada('COMPLETADA'),
  cancelada('CANCELADA');

  const ReservaEstado(this.wireValue);

  final String wireValue;

  static ReservaEstado fromWireValue(String value) =>
      ReservaEstado.values.firstWhere((estado) => estado.wireValue == value);
}
