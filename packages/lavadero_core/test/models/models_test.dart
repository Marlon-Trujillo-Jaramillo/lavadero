import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

void main() {
  test('TenantSummary.fromJson matches GET /api/v1/tenants contract', () {
    final tenant = TenantSummary.fromJson({
      'id': '11111111-1111-1111-1111-111111111111',
      'slug': 'lavadero-central',
      'nombre': 'Lavadero Central',
    });
    expect(tenant.slug, 'lavadero-central');
  });

  test('AuthResponse.fromJson matches login/register contract with '
      'multiple roles', () {
    final auth = AuthResponse.fromJson({
      'accessToken': 'jwt',
      'refreshToken': 'refresh',
      'expiresIn': 900,
      'user': {
        'id': '11111111-1111-1111-1111-111111111111',
        'email': 'empleado@example.com',
        'roles': ['EMPLEADO', 'CLIENTE'],
        'tenantId': '22222222-2222-2222-2222-222222222222',
        'sucursalId': '33333333-3333-3333-3333-333333333333',
      },
    });

    expect(auth.expiresIn, 900);
    expect(auth.user.isEmpleado, isTrue);
    expect(auth.user.isCliente, isTrue);
    expect(auth.user.isAdmin, isFalse);
  });

  test('UserProfile role helpers cover all backend roles', () {
    for (final entry in {
      'CLIENTE': UserRole.cliente,
      'EMPLEADO': UserRole.empleado,
      'ADMIN_SUCURSAL': UserRole.adminSucursal,
      'ADMIN_TENANT': UserRole.adminTenant,
      'SUPER_ADMIN': UserRole.superAdmin,
    }.entries) {
      final user = UserProfile.fromJson({
        'id': '1',
        'email': 'a@b.com',
        'roles': [entry.key],
      });
      expect(user.roles, [entry.value]);
    }
  });

  test('AuthTokens.fromJson matches /auth/refresh contract', () {
    final tokens = AuthTokens.fromJson({
      'accessToken': 'a',
      'refreshToken': 'b',
      'expiresIn': 900,
    });
    expect(tokens.accessToken, 'a');
  });
}
