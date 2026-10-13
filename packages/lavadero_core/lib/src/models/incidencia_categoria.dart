/// Categoría de una [Incidencia], tal como la expone el backend en `incidencia.categoria`.
enum IncidenciaCategoria {
  danioVehiculo('DANIO_VEHICULO', 'Daño al vehículo'),
  clienteAusente('CLIENTE_AUSENTE', 'Cliente ausente'),
  faltanteInsumo('FALTANTE_INSUMO', 'Insumo faltante'),
  otro('OTRO', 'Otro');

  const IncidenciaCategoria(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static IncidenciaCategoria fromWireValue(String value) => IncidenciaCategoria
      .values
      .firstWhere((categoria) => categoria.wireValue == value);
}
