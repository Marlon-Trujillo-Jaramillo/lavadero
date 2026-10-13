/// Cuántas veces se pidió un servicio en el rango del reporte.
class ServicioPopular {
  const ServicioPopular({
    required this.servicioId,
    required this.nombreServicio,
    required this.cantidad,
  });

  factory ServicioPopular.fromJson(Map<String, dynamic> json) =>
      ServicioPopular(
        servicioId: json['servicioId'] as String,
        nombreServicio: json['nombreServicio'] as String,
        cantidad: json['cantidad'] as int,
      );

  final String servicioId;
  final String nombreServicio;
  final int cantidad;
}

/// Resumen de ventas (`GET /api/v1/agenda/reportes/resumen?desde=&hasta=`).
class ResumenVentas {
  const ResumenVentas({
    required this.ingresosTotales,
    required this.moneda,
    required this.totalReservasCompletadas,
    required this.serviciosMasPedidos,
  });

  factory ResumenVentas.fromJson(Map<String, dynamic> json) => ResumenVentas(
    ingresosTotales: (json['ingresosTotales'] as num).toDouble(),
    moneda: json['moneda'] as String,
    totalReservasCompletadas: json['totalReservasCompletadas'] as int,
    serviciosMasPedidos: (json['serviciosMasPedidos'] as List<dynamic>)
        .map((json) => ServicioPopular.fromJson(json as Map<String, dynamic>))
        .toList(),
  );

  final double ingresosTotales;
  final String moneda;
  final int totalReservasCompletadas;
  final List<ServicioPopular> serviciosMasPedidos;
}
