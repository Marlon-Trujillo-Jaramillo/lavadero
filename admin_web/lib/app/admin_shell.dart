import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../features/agenda/agenda_screen.dart';
import '../features/auth/application/admin_auth_controller.dart';
import '../features/branches/branches_screen.dart';
import '../features/catalog_pricing/catalog_pricing_screen.dart';
import '../features/crm/crm_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/employees/employees_screen.dart';
import '../features/inventory/inventory_screen.dart';
import '../features/promotions/promotions_screen.dart';
import '../features/reports/reports_screen.dart';
import '../features/subscription/subscription_screen.dart';
import '../features/tenant_admin/tenant_admin_screen.dart';
import 'session_reset.dart';

/// Shell principal de `admin_web`: barra lateral agrupada (Operación /
/// Negocio / Plataforma) con el usuario abajo; en anchos menores se reduce a
/// un NavigationRail de solo íconos. Cada sección recibe su título en la
/// barra superior del shell, así que las pantallas NO repiten su título.
/// `tenant_admin` solo es visible para SUPER_ADMIN.
class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key, required this.user});

  final UserProfile user;

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Cada montaje del shell es una sesión nueva (login o sesión restaurada): se descarta el
    // estado de la cuenta anterior. `ref` aún no se puede usar en initState.
    reiniciarEstadoDeSesion(ProviderScope.containerOf(context, listen: false));
  }


  List<_Section> _sections(bool isSuperAdmin) => [
    const _Section(
      'Dashboard',
      'Resumen de hoy',
      Icons.space_dashboard_outlined,
      Icons.space_dashboard_rounded,
      _Group.operacion,
      DashboardScreen(),
    ),
    const _Section(
      'Agenda',
      'Reservas de la sucursal',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
      _Group.operacion,
      AgendaScreen(),
    ),
    const _Section(
      'Empleados',
      'Tu equipo y sus accesos',
      Icons.badge_outlined,
      Icons.badge_rounded,
      _Group.operacion,
      EmployeesScreen(),
    ),
    const _Section(
      'Sucursales',
      'Sedes y capacidad',
      Icons.storefront_outlined,
      Icons.storefront_rounded,
      _Group.operacion,
      BranchesScreen(),
    ),
    const _Section(
      'Catálogo y precios',
      'Servicios que ofreces',
      Icons.sell_outlined,
      Icons.sell_rounded,
      _Group.negocio,
      CatalogPricingScreen(),
    ),
    const _Section(
      'Reportes',
      'Ingresos y servicios más pedidos',
      Icons.insights_outlined,
      Icons.insights_rounded,
      _Group.negocio,
      ReportsScreen(),
    ),
    const _Section(
      'Inventario',
      'Insumos del lavadero',
      Icons.inventory_2_outlined,
      Icons.inventory_2_rounded,
      _Group.negocio,
      InventoryScreen(),
    ),
    const _Section(
      'CRM',
      'Tus clientes',
      Icons.groups_outlined,
      Icons.groups_rounded,
      _Group.negocio,
      CrmScreen(),
    ),
    const _Section(
      'Promociones',
      'Descuentos y campañas',
      Icons.local_offer_outlined,
      Icons.local_offer_rounded,
      _Group.negocio,
      PromotionsScreen(),
    ),
    // Pagos de la suscripción: `/api/v1/pagos` es solo ADMIN_TENANT.
    if (widget.user.hasRole(UserRole.adminTenant))
      const _Section(
        'Suscripción',
        'Tu plan y tus pagos',
        Icons.workspace_premium_outlined,
        Icons.workspace_premium_rounded,
        _Group.negocio,
        SubscriptionScreen(),
      ),
    if (isSuperAdmin)
      const _Section(
        'Tenants',
        'Lavaderos y planes de la plataforma',
        Icons.admin_panel_settings_outlined,
        Icons.admin_panel_settings_rounded,
        _Group.plataforma,
        TenantAdminScreen(),
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final sections = _sections(widget.user.isSuperAdmin);
    final safeIndex = _index < sections.length ? _index : 0;
    final current = sections[safeIndex];
    void logout() => ref.read(adminAuthControllerProvider.notifier).logout();

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= LavaderoBreakpoints.shellWide;
        final navigation = wide
            ? _Sidebar(
                sections: sections,
                selected: safeIndex,
                user: widget.user,
                onSelected: (i) => setState(() => _index = i),
                onLogout: logout,
              )
            : _CompactRail(
                sections: sections,
                selected: safeIndex,
                onSelected: (i) => setState(() => _index = i),
                onLogout: logout,
              );
        return Scaffold(
          body: Row(
            children: [
              navigation,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TopBar(section: current),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: LavaderoMotion.normal,
                        switchInCurve: LavaderoMotion.emphasized,
                        child: KeyedSubtree(
                          key: ValueKey(current.label),
                          child: current.screen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _Group {
  operacion('Operación'),
  negocio('Negocio'),
  plataforma('Plataforma');

  const _Group(this.label);

  final String label;
}

class _Section {
  const _Section(
    this.label,
    this.description,
    this.icon,
    this.selectedIcon,
    this.group,
    this.screen,
  );

  final String label;
  final String description;
  final IconData icon;
  final IconData selectedIcon;
  final _Group group;
  final Widget screen;
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.section});

  final _Section section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        LavaderoSpacing.xl,
        LavaderoSpacing.lg,
        LavaderoSpacing.xl,
        LavaderoSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(section.label, style: theme.textTheme.headlineSmall),
          const SizedBox(height: LavaderoSpacing.xxs),
          Text(
            section.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.sections,
    required this.selected,
    required this.user,
    required this.onSelected,
    required this.onLogout,
  });

  final List<_Section> sections;
  final int selected;
  final UserProfile user;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = <Widget>[];
    _Group? lastGroup;
    for (var i = 0; i < sections.length; i++) {
      final section = sections[i];
      if (section.group != lastGroup) {
        lastGroup = section.group;
        items.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              LavaderoSpacing.smd,
              LavaderoSpacing.lg,
              LavaderoSpacing.sm,
              LavaderoSpacing.sm,
            ),
            child: Text(
              section.group.label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      }
      items.add(
        _SidebarItem(
          section: section,
          selected: i == selected,
          onTap: () => onSelected(i),
        ),
      );
    }

    return Container(
      width: LavaderoSizes.sidebarWidth,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                LavaderoSpacing.lg,
                LavaderoSpacing.lg,
                LavaderoSpacing.lg,
                LavaderoSpacing.sm,
              ),
              child: LavaderoLogo(size: LavaderoSizes.logoSm, showWordmark: true),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LavaderoSpacing.smd,
                ),
                children: items,
              ),
            ),
            _UserCard(user: user, onLogout: onLogout),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  final _Section section;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = widget.selected;
    final background = selected
        ? scheme.primaryContainer
        : (_hovered ? scheme.surfaceContainer : LavaderoColors.transparent);
    final foreground = selected ? scheme.onPrimaryContainer : scheme.onSurface;
    final radius = BorderRadius.circular(LavaderoRadii.sm);
    void activar() => widget.onTap();
    // Navegable con teclado: Tab llega a cada sección, Enter/Espacio la abre y
    // el foco se ve con un anillo; los lectores de pantalla la anuncian como
    // botón con su estado "seleccionado".
    return Padding(
      padding: const EdgeInsets.only(bottom: LavaderoSpacing.xxs),
      child: Semantics(
        button: true,
        selected: selected,
        label: widget.section.label,
        excludeSemantics: true,
        child: FocusableActionDetector(
          mouseCursor: SystemMouseCursors.click,
          onShowHoverHighlight: (value) => setState(() => _hovered = value),
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) => activar(),
            ),
            ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
              onInvoke: (_) => activar(),
            ),
          },
          child: GestureDetector(
            onTap: activar,
            child: FocusRing(
              visible: _focused,
              borderRadius: radius,
              child: AnimatedContainer(
                duration: LavaderoMotion.fast,
                curve: LavaderoMotion.emphasized,
                padding: const EdgeInsets.symmetric(
                  horizontal: LavaderoSpacing.smd,
                  vertical: LavaderoSpacing.sm + LavaderoSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: radius,
                ),
                child: Row(
                  children: [
                    Icon(
                      selected
                          ? widget.section.selectedIcon
                          : widget.section.icon,
                      size: LavaderoSizes.iconMd,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: LavaderoSpacing.smd),
                    Expanded(
                      child: Text(
                        widget.section.label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: foreground,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.onLogout});

  final UserProfile user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rol = user.isSuperAdmin
        ? 'Administrador de plataforma'
        : 'Administrador';
    return Container(
      margin: const EdgeInsets.all(LavaderoSpacing.smd),
      padding: const EdgeInsets.all(LavaderoSpacing.smd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(LavaderoRadii.md),
      ),
      child: Row(
        children: [
          AvatarInitials(name: user.email, size: LavaderoSizes.avatarSm + 4),
          const SizedBox(width: LavaderoSpacing.sm + LavaderoSpacing.xxs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
                Text(
                  rol,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, size: LavaderoSizes.iconMd),
            tooltip: 'Cerrar sesión',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}

class _CompactRail extends StatelessWidget {
  const _CompactRail({
    required this.sections,
    required this.selected,
    required this.onSelected,
    required this.onLogout,
  });

  final List<_Section> sections;
  final int selected;
  final ValueChanged<int> onSelected;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(right: BorderSide(color: scheme.outlineVariant)),
      ),
      child: NavigationRail(
        selectedIndex: selected,
        onDestinationSelected: onSelected,
        labelType: NavigationRailLabelType.none,
        leading: const Padding(
          padding: EdgeInsets.symmetric(vertical: LavaderoSpacing.md),
          child: LavaderoLogo(size: LavaderoSizes.logoSm),
        ),
        trailing: Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: LavaderoSpacing.md),
              child: IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Cerrar sesión',
                onPressed: onLogout,
              ),
            ),
          ),
        ),
        destinations: [
          for (final section in sections)
            NavigationRailDestination(
              icon: Tooltip(message: section.label, child: Icon(section.icon)),
              selectedIcon: Icon(section.selectedIcon),
              label: Text(section.label),
            ),
        ],
      ),
    );
  }
}
