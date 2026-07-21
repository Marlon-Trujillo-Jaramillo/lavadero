import 'package:flutter/foundation.dart';

import 'user_role.dart';

/// Usuario autenticado, tal como viene embebido en `AuthResponse.user`.
@immutable
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.roles,
    this.tenantId,
    this.sucursalId,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        email: json['email'] as String,
        roles: (json['roles'] as List<dynamic>)
            .map((value) => UserRole.fromWireValue(value as String))
            .toList(),
        tenantId: json['tenantId'] as String?,
        sucursalId: json['sucursalId'] as String?,
      );

  final String id;
  final String email;
  final List<UserRole> roles;
  final String? tenantId;
  final String? sucursalId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'roles': roles.map((role) => role.wireValue).toList(),
        'tenantId': tenantId,
        'sucursalId': sucursalId,
      };

  bool hasRole(UserRole role) => roles.contains(role);

  bool get isCliente => hasRole(UserRole.cliente);

  bool get isEmpleado => hasRole(UserRole.empleado);

  bool get isAdmin =>
      hasRole(UserRole.adminSucursal) ||
      hasRole(UserRole.adminTenant) ||
      hasRole(UserRole.superAdmin);

  bool get isSuperAdmin => hasRole(UserRole.superAdmin);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          other.id == id &&
          other.email == email &&
          listEquals(other.roles, roles) &&
          other.tenantId == tenantId &&
          other.sucursalId == sucursalId;

  @override
  int get hashCode =>
      Object.hash(id, email, Object.hashAll(roles), tenantId, sucursalId);

  @override
  String toString() =>
      'UserProfile(id: $id, email: $email, roles: $roles, tenantId: $tenantId, sucursalId: $sucursalId)';
}
