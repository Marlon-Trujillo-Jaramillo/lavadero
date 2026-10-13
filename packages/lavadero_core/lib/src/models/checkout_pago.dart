/// Datos firmados por el backend para abrir el Web Checkout de Wompi
/// (`POST /api/v1/pagos/suscripcion`). El cliente NO calcula ni altera nada: el monto y la firma
/// de integridad vienen del servidor.
class CheckoutPago {
  const CheckoutPago({
    required this.pagoId,
    required this.urlCheckout,
    required this.llavePublica,
    required this.referencia,
    required this.montoEnCentavos,
    required this.moneda,
    required this.firmaIntegridad,
    this.urlRedireccion,
  });

  factory CheckoutPago.fromJson(Map<String, dynamic> json) => CheckoutPago(
    pagoId: json['pagoId'] as String,
    urlCheckout: json['urlCheckout'] as String,
    llavePublica: json['llavePublica'] as String,
    referencia: json['referencia'] as String,
    montoEnCentavos: json['montoEnCentavos'] as int,
    moneda: json['moneda'] as String,
    firmaIntegridad: json['firmaIntegridad'] as String,
    urlRedireccion: json['urlRedireccion'] as String?,
  );

  final String pagoId;
  final String urlCheckout;
  final String llavePublica;
  final String referencia;
  final int montoEnCentavos;
  final String moneda;
  final String firmaIntegridad;
  final String? urlRedireccion;

  /// URL completa del Web Checkout (GET) con los parámetros que exige Wompi.
  Uri get uri => Uri.parse(urlCheckout).replace(
    queryParameters: {
      'public-key': llavePublica,
      'currency': moneda,
      'amount-in-cents': '$montoEnCentavos',
      'reference': referencia,
      'signature:integrity': firmaIntegridad,
      if (urlRedireccion != null) 'redirect-url': urlRedireccion!,
    },
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckoutPago &&
          other.pagoId == pagoId &&
          other.urlCheckout == urlCheckout &&
          other.llavePublica == llavePublica &&
          other.referencia == referencia &&
          other.montoEnCentavos == montoEnCentavos &&
          other.moneda == moneda &&
          other.firmaIntegridad == firmaIntegridad &&
          other.urlRedireccion == urlRedireccion;

  @override
  int get hashCode => Object.hash(
    pagoId,
    urlCheckout,
    llavePublica,
    referencia,
    montoEnCentavos,
    moneda,
    firmaIntegridad,
    urlRedireccion,
  );

  @override
  String toString() => 'CheckoutPago(pagoId: $pagoId, referencia: $referencia)';
}
