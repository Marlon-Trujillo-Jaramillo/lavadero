import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/auth_controller.dart';
import 'checklist/checklist_screen.dart';
import 'incidents/incidents_screen.dart';
import 'shifts/shifts_screen.dart';

/// Shell de navegación para usuarios con rol EMPLEADO.
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 3) {
            ref.read(authControllerProvider.notifier).logout();
            return;
          }
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            label: 'Turnos',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            label: 'Checklist',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_problem_outlined),
            label: 'Incidencias',
          ),
          NavigationDestination(
            icon: Icon(Icons.logout_outlined),
            label: 'Salir',
          ),
        ],
      ),
    );
  }
}
