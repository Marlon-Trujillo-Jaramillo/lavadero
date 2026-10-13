import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'checklist/application/checklist_controller.dart';
import 'checklist/checklist_screen.dart';
import 'incidents/application/incidents_controller.dart';
import 'incidents/incidents_screen.dart';
import 'shifts/application/agenda_controller.dart';
import 'shifts/shifts_screen.dart';

/// Shell de navegación para usuarios con rol EMPLEADO. "Cerrar sesión" vive
/// en el avatar de cada pantalla (`ProfileMenuButton`), no en la barra.
class EmpleadoShell extends ConsumerStatefulWidget {
  const EmpleadoShell({super.key});

  @override
  ConsumerState<EmpleadoShell> createState() => _EmpleadoShellState();
}

class _EmpleadoShellState extends ConsumerState<EmpleadoShell> {
  int _index = 0;

  static const _screens = [
    ShiftsScreen(),
    ChecklistScreen(),
    IncidentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Controllers no autoDispose: se descartan los datos de una sesión
    // anterior (otra cuenta en el mismo dispositivo).
    // (`ref` no puede usarse aún en initState: se va directo al container.)
    ProviderScope.containerOf(context, listen: false)
      ..invalidate(agendaControllerProvider)
      ..invalidate(checklistControllerProvider)
      ..invalidate(incidentsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: LavaderoMotion.normal,
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.view_timeline_outlined),
            selectedIcon: Icon(Icons.view_timeline_rounded),
            label: 'Turnos',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Checklist',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            selectedIcon: Icon(Icons.report_problem_rounded),
            label: 'Incidencias',
          ),
        ],
      ),
    );
  }
}
