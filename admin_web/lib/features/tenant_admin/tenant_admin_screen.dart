import 'package:flutter/material.dart';

import '../shared/widgets/coming_soon_placeholder.dart';

/// Solo visible para SUPER_ADMIN: onboarding de nuevos tenants.
class TenantAdminScreen extends StatelessWidget {
  const TenantAdminScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const ComingSoonPlaceholder(title: 'Administración de tenants');
}
