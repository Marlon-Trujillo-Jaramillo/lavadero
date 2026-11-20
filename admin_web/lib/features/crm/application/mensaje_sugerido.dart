import 'package:lavadero_core/lavadero_core.dart';

/// Correo sugerido para un cliente según su segmento: agradecer al nuevo,
/// reconocer al frecuente, invitar de vuelta al que está en riesgo. El
/// dueño lo revisa y lo envía desde su propio correo (`mailto:`): la app
/// no manda nada sola.
({String asunto, String cuerpo}) mensajeSugerido(ClienteCrm cliente) {
  final nombre = _primerNombre(cliente.nombre);
  return switch (cliente.segmento) {
    SegmentoCliente.nuevo => (
      asunto: '¡Gracias por tu primera visita!',
      cuerpo:
          'Hola $nombre, gracias por confiarnos tu vehículo. Esperamos que '
          'te haya gustado el resultado. Cuando quieras volver, puedes '
          'reservar desde la app en segundos.',
    ),
    SegmentoCliente.frecuente => (
      asunto: 'Gracias por ser parte de la casa',
      cuerpo:
          'Hola $nombre, ya son ${cliente.visitas} visitas con nosotros. '
          'Gracias por preferirnos: clientes como tú son los que nos hacen '
          'crecer.',
    ),
    SegmentoCliente.enRiesgo => (
      asunto: 'Te extrañamos, $nombre',
      cuerpo:
          'Hola $nombre, hace ${cliente.diasSinVenir() ?? 0} días no te '
          'vemos por el lavadero. ¿Le damos una consentida a tu vehículo '
          'esta semana? Reserva desde la app cuando te quede bien.',
    ),
    SegmentoCliente.ocasional => (
      asunto: 'Tu vehículo te lo va a agradecer',
      cuerpo:
          'Hola $nombre, ¿cómo va tu vehículo? Si quieres dejarlo como '
          'nuevo, puedes reservar desde la app y elegir la hora que te '
          'sirva.',
    ),
    SegmentoCliente.sinVisitas => (
      asunto: 'Tu primer lavado te espera',
      cuerpo:
          'Hola $nombre, ya tienes tu cuenta lista. Reserva tu primer '
          'servicio desde la app y elige la sucursal y la hora que te '
          'queden mejor.',
    ),
  };
}

/// `mailto:` con el asunto y el cuerpo sugeridos ya escritos.
Uri correoSugerido(ClienteCrm cliente) {
  final mensaje = mensajeSugerido(cliente);
  return Uri(
    scheme: 'mailto',
    path: cliente.email,
    query: _codificar({'subject': mensaje.asunto, 'body': mensaje.cuerpo}),
  );
}

/// `Uri(queryParameters:)` codifica los espacios como `+`, que los clientes
/// de correo muestran literal; `mailto` necesita `%20`.
String _codificar(Map<String, String> parametros) => parametros.entries
    .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
    .join('&');

String _primerNombre(String nombre) {
  final partes = nombre.trim().split(RegExp(r'\s+'));
  return partes.first.isEmpty ? nombre : partes.first;
}
