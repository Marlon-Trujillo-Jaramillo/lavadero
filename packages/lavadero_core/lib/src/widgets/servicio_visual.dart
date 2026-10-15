import 'package:flutter/material.dart';
import '../format/formato.dart';
import '../models/service_item.dart';
import '../theme/design_tokens.dart';

/// Ícono y color de acento de un servicio del catálogo (compartido por
/// `mobile_app` y `admin_web`). El backend no
/// guarda ícono, así que se infiere del nombre (con un respaldo estable por
/// id para que el mismo servicio siempre se vea igual).
extension ServicioVisual on ServiceItem {
  IconData get icono {
    final n = nombre.toLowerCase();
    if (n.contains('premium') || n.contains('full') || n.contains('complet')) {
      return Icons.auto_awesome_rounded;
    }
    if (n.contains('cera') || n.contains('encerad') || n.contains('pul')) {
      return Icons.diamond_outlined;
    }
    if (n.contains('interior') || n.contains('aspir') || n.contains('tapic')) {
      return Icons.airline_seat_recline_normal_rounded;
    }
    if (n.contains('motor')) return Icons.settings_rounded;
    if (n.contains('moto')) return Icons.two_wheeler_rounded;
    return Icons.water_drop_rounded;
  }

  Color get colorAcento {
    const paleta = [
      LavaderoColors.ocean,
      LavaderoColors.aqua,
      LavaderoColors.success,
      LavaderoColors.warning,
      LavaderoColors.info,
    ];
    return paleta[id.hashCode.abs() % paleta.length];
  }

  String get precioTexto => Formato.moneda(precio, moneda);

  String get duracionTexto =>
      Formato.duracion(Duration(minutes: duracionEstimadaMinutos));
}

/// Texto legible de una feature de plan: el backend guarda claves
/// (`agenda_basica`); en pantalla va "Agenda básica".
abstract final class FeaturePlan {
  static const _conocidas = {
    'agenda_basica': 'Agenda básica',
    'agenda_avanzada': 'Agenda avanzada',
    'facturacion_basica': 'Facturación básica',
    'facturacion_electronica': 'Facturación electrónica',
    'reportes': 'Reportes',
    'reportes_avanzados': 'Reportes avanzados',
    'multi_sucursal': 'Varias sucursales',
    'crm': 'CRM de clientes',
    'promociones': 'Promociones',
    'inventario': 'Inventario',
  };

  static String etiqueta(String clave) {
    final conocida = _conocidas[clave.trim().toLowerCase()];
    if (conocida != null) return conocida;
    final texto = clave.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (texto.isEmpty) return clave;
    return texto[0].toUpperCase() + texto.substring(1);
  }
}
