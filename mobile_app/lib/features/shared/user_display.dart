import 'package:lavadero_core/lavadero_core.dart';

/// Presentación del usuario autenticado. `UserProfile` no trae nombre (solo
/// email), así que el saludo se deriva de la parte local del email:
/// `ana.perez@x.com` → `Ana`.
extension UserDisplay on UserProfile {
  String get nombreCorto {
    final local = email.split('@').first;
    final primera = local
        .split(RegExp(r'[._\-+0-9]+'))
        .firstWhere((p) => p.isNotEmpty, orElse: () => local);
    if (primera.isEmpty) return email;
    return primera[0].toUpperCase() + primera.substring(1).toLowerCase();
  }

  /// Roles legibles para el menú de cuenta.
  List<String> get rolesLegibles => [
    if (isCliente) 'Cliente',
    if (isEmpleado) 'Empleado',
    if (isAdmin) 'Administrador',
  ];
}
