import 'reserva_estado.dart';
import 'vehiculo.dart';

/// Segmento de un cliente en el CRM. La regla la calcula el backend (ver
/// `SegmentoCliente.java`); aquí solo vive cómo se nombra y explica.
enum SegmentoCliente {
  nuevo('NUEVO', 'Nuevos', 'Su primera visita fue este mes.'),
  frecuente(
    'FRECUENTE',
    'Frecuentes',
    'Cuatro visitas o más y vuelven al menos una vez al mes.',
  ),
  ocasional('OCASIONAL', 'Ocasionales', 'Vienen de vez en cuando.'),
  enRiesgo(
    'EN_RIESGO',
    'En riesgo',
    'Ya deberían haber vuelto según su ritmo y no tienen reserva.',
  ),
  sinVisitas(
    'SIN_VISITAS',
    'Sin visitas',
    'Tienen cuenta pero aún no completan un servicio.',
  );

  const SegmentoCliente(this.wireValue, this.label, this.descripcion);

  final String wireValue;
  final String label;
  final String descripcion;

  static SegmentoCliente fromWireValue(String value) =>
      SegmentoCliente.values.firstWhere((s) => s.wireValue == value);
}

/// Orden de la lista del CRM.
enum OrdenClientes {
  ultimaVisita('ULTIMA_VISITA', 'Última visita'),
  gasto('GASTO', 'Mayor gasto'),
  visitas('VISITAS', 'Más visitas'),
  nombre('NOMBRE', 'Nombre');

  const OrdenClientes(this.wireValue, this.label);

  final String wireValue;
  final String label;
}

/// Una fila del CRM (`/api/v1/crm/clientes`).
class ClienteCrm {
  const ClienteCrm({
    required this.id,
    required this.nombre,
    required this.email,
    required this.visitas,
    required this.gastoTotal,
    required this.moneda,
    this.primeraVisita,
    this.ultimaVisita,
    this.proximaReserva,
    required this.vehiculosActivos,
    required this.segmento,
  });

  factory ClienteCrm.fromJson(Map<String, dynamic> json) => ClienteCrm(
    id: json['id'] as String,
    nombre: json['nombre'] as String,
    email: json['email'] as String,
    visitas: json['visitas'] as int,
    gastoTotal: json['gastoTotal'] as num,
    moneda: json['moneda'] as String,
    primeraVisita: _fecha(json['primeraVisita']),
    ultimaVisita: _fecha(json['ultimaVisita']),
    proximaReserva: _fecha(json['proximaReserva']),
    vehiculosActivos: json['vehiculosActivos'] as int,
    segmento: SegmentoCliente.fromWireValue(json['segmento'] as String),
  );

  final String id;
  final String nombre;
  final String email;
  final int visitas;
  final num gastoTotal;
  final String moneda;
  final DateTime? primeraVisita;
  final DateTime? ultimaVisita;
  final DateTime? proximaReserva;
  final int vehiculosActivos;
  final SegmentoCliente segmento;

  /// Días desde la última visita, o `null` si nunca vino.
  int? diasSinVenir({DateTime? ahora}) => ultimaVisita == null
      ? null
      : (ahora ?? DateTime.now()).difference(ultimaVisita!).inDays;
}

/// Una página del CRM con el total y el conteo por segmento (el conteo no
/// depende del segmento elegido, para mostrarlo en los filtros).
class PaginaClientes {
  const PaginaClientes({
    required this.clientes,
    required this.total,
    required this.pagina,
    required this.tamano,
    required this.porSegmento,
  });

  factory PaginaClientes.fromJson(Map<String, dynamic> json) {
    final conteo = json['porSegmento'] as Map<String, dynamic>;
    return PaginaClientes(
      clientes: (json['clientes'] as List<dynamic>)
          .map((e) => ClienteCrm.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      pagina: json['pagina'] as int,
      tamano: json['tamano'] as int,
      porSegmento: {
        for (final segmento in SegmentoCliente.values)
          segmento: (conteo[segmento.wireValue] as int?) ?? 0,
      },
    );
  }

  final List<ClienteCrm> clientes;
  final int total;
  final int pagina;
  final int tamano;
  final Map<SegmentoCliente, int> porSegmento;

  int get totalClientes => porSegmento.values.fold(0, (a, b) => a + b);
  bool get hayMas => (pagina + 1) * tamano < total;
}

/// Una reserva del historial en la ficha del cliente.
class VisitaCliente {
  const VisitaCliente({
    required this.reservaId,
    required this.fecha,
    required this.servicio,
    required this.sucursal,
    required this.estado,
    required this.precio,
    required this.moneda,
    this.placa,
  });

  factory VisitaCliente.fromJson(Map<String, dynamic> json) => VisitaCliente(
    reservaId: json['reservaId'] as String,
    fecha: DateTime.parse(json['fecha'] as String),
    servicio: json['servicio'] as String,
    sucursal: json['sucursal'] as String,
    estado: ReservaEstado.fromWireValue(json['estado'] as String),
    precio: json['precio'] as num,
    moneda: json['moneda'] as String,
    placa: json['placa'] as String?,
  );

  final String reservaId;
  final DateTime fecha;
  final String servicio;
  final String sucursal;
  final ReservaEstado estado;
  final num precio;
  final String moneda;
  final String? placa;
}

/// Ficha del cliente (`/api/v1/crm/clientes/{id}`).
class FichaCliente {
  const FichaCliente({
    required this.cliente,
    this.servicioFavorito,
    required this.vehiculos,
    required this.historial,
  });

  factory FichaCliente.fromJson(Map<String, dynamic> json) => FichaCliente(
    cliente: ClienteCrm.fromJson(json['cliente'] as Map<String, dynamic>),
    servicioFavorito: json['servicioFavorito'] as String?,
    vehiculos: (json['vehiculos'] as List<dynamic>)
        .map((e) => Vehiculo.fromJson(e as Map<String, dynamic>))
        .toList(),
    historial: (json['historial'] as List<dynamic>)
        .map((e) => VisitaCliente.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  final ClienteCrm cliente;
  final String? servicioFavorito;
  final List<Vehiculo> vehiculos;
  final List<VisitaCliente> historial;
}

DateTime? _fecha(Object? valor) =>
    valor == null ? null : DateTime.parse(valor as String);
