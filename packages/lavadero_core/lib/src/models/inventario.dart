/// Unidad de un insumo (`ML`, `G`, `UNIDAD`).
enum UnidadMedida {
  ml('ML', 'ml', 'Mililitros'),
  g('G', 'g', 'Gramos'),
  unidad('UNIDAD', 'und', 'Unidades');

  const UnidadMedida(this.wireValue, this.corto, this.label);

  final String wireValue;
  final String corto;
  final String label;

  static UnidadMedida fromWireValue(String value) =>
      UnidadMedida.values.firstWhere((u) => u.wireValue == value);
}

/// Un insumo con su stock en la sucursal consultada
/// (`/api/v1/inventario/insumos`).
class InsumoStock {
  const InsumoStock({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.costoUnitario,
    required this.moneda,
    required this.sucursalId,
    required this.cantidad,
    required this.minimo,
    required this.bajoMinimo,
  });

  factory InsumoStock.fromJson(Map<String, dynamic> json) => InsumoStock(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    unidad: UnidadMedida.fromWireValue(json['unidad'] as String),
    costoUnitario: json['costoUnitario'] as num,
    moneda: json['moneda'] as String,
    sucursalId: json['sucursalId'] as String,
    cantidad: json['cantidad'] as num,
    minimo: json['minimo'] as num,
    bajoMinimo: json['bajoMinimo'] as bool,
  );

  final String id;
  final String nombre;
  final UnidadMedida unidad;
  final num costoUnitario;
  final String moneda;
  final String sucursalId;
  final num cantidad;
  final num minimo;
  final bool bajoMinimo;

  /// Lo que vale lo que hay en bodega (0 si el stock es negativo).
  num get valorEnBodega => cantidad > 0 ? cantidad * costoUnitario : 0;
}

enum TipoMovimiento {
  entrada('ENTRADA', 'Entrada'),
  consumo('CONSUMO', 'Consumo'),
  ajuste('AJUSTE', 'Ajuste');

  const TipoMovimiento(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static TipoMovimiento fromWireValue(String value) =>
      TipoMovimiento.values.firstWhere((t) => t.wireValue == value);
}

/// Una línea del kardex de un insumo.
class MovimientoInventario {
  const MovimientoInventario({
    required this.id,
    required this.tipo,
    required this.cantidad,
    required this.saldo,
    this.reservaId,
    this.nota,
    required this.creadoEn,
  });

  factory MovimientoInventario.fromJson(Map<String, dynamic> json) =>
      MovimientoInventario(
        id: json['id'] as String,
        tipo: TipoMovimiento.fromWireValue(json['tipo'] as String),
        cantidad: json['cantidad'] as num,
        saldo: json['saldo'] as num,
        reservaId: json['reservaId'] as String?,
        nota: json['nota'] as String?,
        creadoEn: DateTime.parse(json['creadoEn'] as String),
      );

  final String id;
  final TipoMovimiento tipo;
  final num cantidad;
  final num saldo;
  final String? reservaId;
  final String? nota;
  final DateTime creadoEn;
}

/// Una línea de la receta de un servicio con su costo.
class LineaCosto {
  const LineaCosto({
    required this.insumoId,
    required this.insumo,
    required this.unidad,
    required this.cantidad,
    required this.costo,
  });

  factory LineaCosto.fromJson(Map<String, dynamic> json) => LineaCosto(
    insumoId: json['insumoId'] as String,
    insumo: json['insumo'] as String,
    unidad: UnidadMedida.fromWireValue(json['unidad'] as String),
    cantidad: json['cantidad'] as num,
    costo: json['costo'] as num,
  );

  final String insumoId;
  final String insumo;
  final UnidadMedida unidad;
  final num cantidad;
  final num costo;
}

/// Costo de insumos y margen de un servicio (`/api/v1/inventario/costos`).
class CostoServicio {
  const CostoServicio({
    required this.servicioId,
    required this.nombre,
    required this.activo,
    required this.precio,
    required this.moneda,
    required this.lineas,
    required this.costoInsumos,
    required this.margen,
    this.margenPorcentaje,
  });

  factory CostoServicio.fromJson(Map<String, dynamic> json) => CostoServicio(
    servicioId: json['servicioId'] as String,
    nombre: json['nombre'] as String,
    activo: json['activo'] as bool,
    precio: json['precio'] as num,
    moneda: json['moneda'] as String,
    lineas: (json['lineas'] as List<dynamic>)
        .map((e) => LineaCosto.fromJson(e as Map<String, dynamic>))
        .toList(),
    costoInsumos: json['costoInsumos'] as num,
    margen: json['margen'] as num,
    margenPorcentaje: json['margenPorcentaje'] as int?,
  );

  final String servicioId;
  final String nombre;
  final bool activo;
  final num precio;
  final String moneda;
  final List<LineaCosto> lineas;
  final num costoInsumos;
  final num margen;
  final int? margenPorcentaje;

  bool get tieneReceta => lineas.isNotEmpty;
}
