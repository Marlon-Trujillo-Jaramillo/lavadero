/// Formatos de presentación compartidos (sin depender de `intl`, que no es
/// dependencia del proyecto). Antes cada pantalla armaba su propio
/// `'\$${precio.toStringAsFixed(0)}'`, sin separador de miles.
abstract final class Formato {
  /// Monedas que en la práctica no usan decimales.
  static const _sinDecimales = {'COP', 'CLP', 'PYG', 'JPY'};

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const _dias = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

  /// `45000, 'COP'` → `$45.000`; `12.5, 'USD'` → `$12,50`.
  static String moneda(num monto, String codigoMoneda) {
    final decimales = _sinDecimales.contains(codigoMoneda.toUpperCase())
        ? 0
        : 2;
    final negativo = monto < 0;
    final fijo = monto.abs().toStringAsFixed(decimales);
    final partes = fijo.split('.');
    final entero = _agruparMiles(partes.first);
    final fraccion = decimales > 0 ? ',${partes[1]}' : '';
    return '${negativo ? '-' : ''}\$$entero$fraccion';
  }

  /// `45000` → `45 mil`; `1250000` → `1,3 M`. Para KPIs compactos.
  static String compacto(num valor) {
    final abs = valor.abs();
    if (abs >= 1000000) {
      return '${_unDecimal(valor / 1000000)} M';
    }
    if (abs >= 1000) return '${_unDecimal(valor / 1000)} mil';
    return valor.toStringAsFixed(0);
  }

  /// `45 min`, `2 h`, `2 h 15 min`. Duraciones legibles (nada de "374 min").
  static String duracion(Duration d) {
    final minutos = d.inMinutes < 1 ? 1 : d.inMinutes;
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    if (horas == 0) return '$minutos min';
    return resto == 0 ? '$horas h' : '$horas h $resto min';
  }

  /// `14:05`.
  static String hora(DateTime fechaHora) =>
      '${_dos(fechaHora.hour)}:${_dos(fechaHora.minute)}';

  /// `12/10/2026`.
  static String fecha(DateTime fecha) =>
      '${_dos(fecha.day)}/${_dos(fecha.month)}/${fecha.year}';

  /// `12/10/2026 14:05`.
  static String fechaHora(DateTime fechaHora) =>
      '${fecha(fechaHora)} ${hora(fechaHora)}';

  /// `lun 12 oct`.
  static String fechaCorta(DateTime fecha) =>
      '${_dias[fecha.weekday - 1]} ${fecha.day} ${_meses[fecha.month - 1]}';

  /// "Hoy", "Mañana", "Ayer" o la fecha corta.
  static String diaRelativo(DateTime fecha, {DateTime? ahora}) {
    final hoy = _soloFecha(ahora ?? DateTime.now());
    final dias = _soloFecha(fecha).difference(hoy).inDays;
    return switch (dias) {
      0 => 'Hoy',
      1 => 'Mañana',
      -1 => 'Ayer',
      _ => fechaCorta(fecha),
    };
  }

  static DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _dos(int n) => n.toString().padLeft(2, '0');

  static String _unDecimal(num v) {
    final texto = v.toStringAsFixed(1);
    return (texto.endsWith('.0') ? texto.substring(0, texto.length - 2) : texto)
        .replaceAll('.', ',');
  }

  static String _agruparMiles(String digitos) {
    final buffer = StringBuffer();
    for (var i = 0; i < digitos.length; i++) {
      if (i > 0 && (digitos.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digitos[i]);
    }
    return buffer.toString();
  }
}
