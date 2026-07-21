import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../features/auth/application/admin_auth_controller.dart';
import '../features/branches/branches_screen.dart';
import '../features/catalog_pricing/catalog_pricing_screen.dart';
import '../features/crm/crm_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/employees/employees_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/promotions/promotions_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/tenant_admin/tenant_admin_screen.dart';

/// Shell principal de `admin_web`: navegación lateral (NavigationRail, ideal
/// para web/desktop) entre las secciones de administración del tenant, más
/// `tenant_admin` (solo visible para SUPER_ADMIN).
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.user});

  final UserProfile user;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final isSuperAdmin = widget.user.isSuperAdmin;

    final destinations = <_Section>[
      const _Section('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
      const _Section('Empleados', Icons.people_outline, EmployeesScreen()),
      const _Section(
        'Catálogo y precios',
        Icons.sell_outlined,
        CatalogPricingScreen(),
      ),
      const _Section(
        'Inventario',
        Icons.inventory_2_outlined,
        InventoryScreen(),
      ),
      const _Section(
        'Sucursales',
        Icons.store_mall_directory_outlined,
        BranchesScreen(),
      ),
      const _Section('CRM', Icons.contacts_outlined, CrmScreen()),
      const _Section('Reportes', Icons.bar_chart_outlined, ReportsScreen()),
      const _Section(
        'Promociones',
        Icons.local_offer_outlined,
        PromotionsScreen(),
      ),
      if (isSuperAdmin)
        const _Section(
          'Tenants',
          Icons.admin_panel_settings_outlined,
          TenantAdminScreen(),
        ),
    ];

    final safeIndex = _index < destinations.length ? _index : 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[safeIndex].label),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Cerrar sesión',
            onPressed: () =>
                ref.read(adminAuthControllerProvider.notifier).logout(),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: safeIndex,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final section in destinations)
                NavigationRailDestination(
                  icon: Icon(section.icon),
                  label: Text(section.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: destinations[safeIndex].screen),
        ],
      ),
    );
  }
}

class _Section {
  const _Section(this.label, this.icon, this.screen);

  final String label;
  final IconData icon;
  final Widget screen;
}
