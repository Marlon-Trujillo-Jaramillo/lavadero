/// Un pago de suscripción del tenant (`GET /api/v1/pagos`). El estado lo fija el webhook de
/// Wompi en el backend, nunca el cliente.
class Pago {
  const Pago({
    required this.id,
    required this.subscriptionPlanId,
    required this.monto,
    required this.moneda,
    required this.referencia,
    required this.estado,
    required this.creadoEn,
  });

  factory Pago.fromJson(Map<String, dynamic> json) => Pago(
    id: json['id'] as String,
    subscriptionPlanId: json['subscriptionPlanId'] as String,
    monto: (json['monto'] as num).toDouble(),
    moneda: json['moneda'] as String,
    referencia: json['referencia'] as String,
    estado: PagoEstado.fromWireValue(json['estado'] as String),
    creadoEn: DateTime.parse(json['creadoEn'] as String),
  );

  final String id;
  final String subscriptionPlanId;
  final double monto;
  final String moneda;
  final String referencia;
  final PagoEstado estado;
  final DateTime creadoEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Pago &&
          other.id == id &&
          other.subscriptionPlanId == subscriptionPlanId &&
          other.monto == monto &&
          other.moneda == moneda &&
          other.referencia == referencia &&
          other.estado == estado &&
          other.creadoEn == creadoEn;

  @override
  int get hashCode => Object.hash(
    id,
    subscriptionPlanId,
    monto,
    moneda,
    referencia,
    estado,
    creadoEn,
  );

  @override
  String toString() => 'Pago(id: $id, monto: $monto $moneda, estado: $estado)';
}

enum PagoEstado {
  pendiente('PENDIENTE'),
  aprobado('APROBADO'),
  rechazado('RECHAZADO');

  const PagoEstado(this.wireValue);

  final String wireValue;

  static PagoEstado fromWireValue(String value) => PagoEstado.values.firstWhere(
    (e) => e.wireValue == value,
    orElse: () => throw ArgumentError('PagoEstado desconocido: $value'),
  );
}
