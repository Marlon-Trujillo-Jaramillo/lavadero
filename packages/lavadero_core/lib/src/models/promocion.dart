/// Cómo se activa una promoción (`/api/v1/promociones`).
enum TipoPromocion {
  cupon('CUPON', 'Cupón'),
  horario('HORARIO', 'Precio por horario');

  const TipoPromocion(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static TipoPromocion fromWireValue(String value) =>
      TipoPromocion.values.firstWhere((t) => t.wireValue == value);
}

enum TipoDescuento {
  porcentaje('PORCENTAJE'),
  montoFijo('MONTO_FIJO');

  const TipoDescuento(this.wireValue);

  final String wireValue;

  static TipoDescuento fromWireValue(String value) =>
      TipoDescuento.values.firstWhere((t) => t.wireValue == value);
}

/// Día de la semana en el contrato de la API (`MONDAY` ... `SUNDAY`).
enum DiaSemana {
  lunes('MONDAY', 'Lun'),
  martes('TUESDAY', 'Mar'),
  miercoles('WEDNESDAY', 'Mié'),
  jueves('THURSDAY', 'Jue'),
  viernes('FRIDAY', 'Vie'),
  sabado('SATURDAY', 'Sáb'),
  domingo('SUNDAY', 'Dom');

  const DiaSemana(this.wireValue, this.corto);

  final String wireValue;
  final String corto;

  static DiaSemana fromWireValue(String value) =>
      DiaSemana.values.firstWhere((d) => d.wireValue == value);
}

/// Una promoción con sus resultados.
class Promocion {
  const Promocion({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.codigo,
    required this.tipoDescuento,
    required this.valorDescuento,
    this.moneda,
    this.dias = const [],
    this.horaDesde,
    this.horaHasta,
    required this.vigenteDesde,
    required this.vigenteHasta,
    this.usosMaximos,
    required this.usos,
    required this.activa,
    required this.reservas,
    required this.completadas,
    required this.ingresos,
    required this.descuentoOtorgado,
  });

  factory Promocion.fromJson(Map<String, dynamic> json) => Promocion(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    tipo: TipoPromocion.fromWireValue(json['tipo'] as String),
    codigo: json['codigo'] as String?,
    tipoDescuento: TipoDescuento.fromWireValue(json['tipoDescuento'] as String),
    valorDescuento: json['valorDescuento'] as num,
    moneda: json['moneda'] as String?,
    dias: ((json['dias'] as List<dynamic>?) ?? const [])
        .map((d) => DiaSemana.fromWireValue(d as String))
        .toList(),
    horaDesde: json['horaDesde'] as String?,
    horaHasta: json['horaHasta'] as String?,
    vigenteDesde: DateTime.parse(json['vigenteDesde'] as String),
    vigenteHasta: DateTime.parse(json['vigenteHasta'] as String),
    usosMaximos: json['usosMaximos'] as int?,
    usos: json['usos'] as int,
    activa: json['activa'] as bool,
    reservas: json['reservas'] as int,
    completadas: json['completadas'] as int,
    ingresos: json['ingresos'] as num,
    descuentoOtorgado: json['descuentoOtorgado'] as num,
  );

  final String id;
  final String nombre;
  final TipoPromocion tipo;
  final String? codigo;
  final TipoDescuento tipoDescuento;
  final num valorDescuento;
  final String? moneda;
  final List<DiaSemana> dias;

  /// `HH:mm:ss` tal como lo envía el backend.
  final String? horaDesde;
  final String? horaHasta;
  final DateTime vigenteDesde;
  final DateTime vigenteHasta;
  final int? usosMaximos;
  final int usos;
  final bool activa;
  final int reservas;
  final int completadas;
  final num ingresos;
  final num descuentoOtorgado;

  /// "Lun, Mar · 08:00–11:00".
  String? get franja {
    if (horaDesde == null || horaHasta == null) return null;
    final dias = this.dias.map((d) => d.corto).join(', ');
    return '$dias · ${_hhmm(horaDesde!)}–${_hhmm(horaHasta!)}';
  }

  /// Vencida por fecha (independiente de [activa]).
  bool vencida({DateTime? hoy}) {
    final ahora = hoy ?? DateTime.now();
    return DateTime(ahora.year, ahora.month, ahora.day).isAfter(vigenteHasta);
  }

  static String _hhmm(String hora) =>
      hora.length >= 5 ? hora.substring(0, 5) : hora;
}

/// Precio de una reserva antes de crearla (`/api/v1/promociones/cotizacion`).
class Cotizacion {
  const Cotizacion({
    required this.precioLista,
    required this.descuento,
    required this.precioFinal,
    required this.moneda,
    this.promocionId,
    this.promocionNombre,
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) => Cotizacion(
    precioLista: json['precioLista'] as num,
    descuento: json['descuento'] as num,
    precioFinal: json['precioFinal'] as num,
    moneda: json['moneda'] as String,
    promocionId: json['promocionId'] as String?,
    promocionNombre: json['promocionNombre'] as String?,
  );

  final num precioLista;
  final num descuento;
  final num precioFinal;
  final String moneda;
  final String? promocionId;
  final String? promocionNombre;

  bool get tieneDescuento => promocionId != null && descuento > 0;
}
