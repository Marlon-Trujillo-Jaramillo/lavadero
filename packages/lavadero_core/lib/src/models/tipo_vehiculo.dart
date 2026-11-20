/// Tipos de vehículo (`TipoVehiculo` del backend) — ver docs/specs/009-mis-vehiculos.md.
enum TipoVehiculo {
  automovil('AUTOMOVIL', 'Automóvil'),
  camioneta('CAMIONETA', 'Camioneta'),
  moto('MOTO', 'Moto'),
  otro('OTRO', 'Otro');

  const TipoVehiculo(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static TipoVehiculo fromWireValue(String value) => TipoVehiculo.values
      .firstWhere((t) => t.wireValue == value, orElse: () => TipoVehiculo.otro);
}
