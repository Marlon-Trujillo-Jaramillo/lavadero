/// Categoría de un gasto operativo del lavadero. `wireValue` es el nombre que
/// viaja a la API; `label`, el texto para el dueño.
enum CategoriaGasto {
  arriendo('ARRIENDO', 'Arriendo'),
  nomina('NOMINA', 'Nómina'),
  insumos('INSUMOS', 'Insumos'),
  serviciosPublicos('SERVICIOS_PUBLICOS', 'Servicios públicos'),
  mantenimiento('MANTENIMIENTO', 'Mantenimiento'),
  otro('OTRO', 'Otro');

  const CategoriaGasto(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static CategoriaGasto fromWire(String value) => values.firstWhere(
    (c) => c.wireValue == value,
    orElse: () => CategoriaGasto.otro,
  );
}

/// Un gasto operativo (`GET/POST /api/v1/gastos`).
class Gasto {
  const Gasto({
    required this.id,
    required this.fecha,
    required this.categoria,
    required this.descripcion,
    required this.monto,
    required this.moneda,
    this.sucursalId,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) => Gasto(
    id: json['id'] as String,
    sucursalId: json['sucursalId'] as String?,
    fecha: DateTime.parse(json['fecha'] as String),
    categoria: CategoriaGasto.fromWire(json['categoria'] as String),
    descripcion: json['descripcion'] as String,
    monto: (json['monto'] as num).toDouble(),
    moneda: json['moneda'] as String,
  );

  final String id;
  final String? sucursalId;
  final DateTime fecha;
  final CategoriaGasto categoria;
  final String descripcion;
  final double monto;
  final String moneda;
}

/// Ingresos, gastos y utilidad de un periodo (`GET /api/v1/finanzas/resumen`).
/// La utilidad puede ser negativa.
class ResumenFinanciero {
  const ResumenFinanciero({
    required this.ingresos,
    required this.gastos,
    required this.utilidad,
    required this.moneda,
  });

  factory ResumenFinanciero.fromJson(Map<String, dynamic> json) =>
      ResumenFinanciero(
        ingresos: (json['ingresos'] as num).toDouble(),
        gastos: (json['gastos'] as num).toDouble(),
        utilidad: (json['utilidad'] as num).toDouble(),
        moneda: json['moneda'] as String,
      );

  final double ingresos;
  final double gastos;
  final double utilidad;
  final String moneda;
}
