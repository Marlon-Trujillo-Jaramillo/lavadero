/// Roles posibles de un usuario autenticado, tal como los expone el backend
/// en `user.roles` dentro de las respuestas de `/api/v1/auth/*`.
enum UserRole {
  cliente('CLIENTE'),
  empleado('EMPLEADO'),
  adminSucursal('ADMIN_SUCURSAL'),
  adminTenant('ADMIN_TENANT'),
  superAdmin('SUPER_ADMIN');

  const UserRole(this.wireValue);

  /// Valor tal como lo envía/espera el backend.
  final String wireValue;

  static UserRole fromWireValue(String value) =>
      UserRole.values.firstWhere((role) => role.wireValue == value);
}
