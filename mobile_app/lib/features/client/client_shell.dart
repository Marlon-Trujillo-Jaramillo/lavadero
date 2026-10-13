import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'booking/application/booking_controller.dart';
import 'booking/booking_screen.dart';
import 'catalog/application/catalog_controller.dart';
import 'catalog/catalog_screen.dart';
import 'client_navigation.dart';
import 'reservations/application/my_reservations_controller.dart';
import 'reservations/presentation/my_reservations_screen.dart';
import 'vehicles/vehicles_screen.dart';

/// Shell de navegación para usuarios con rol CLIENTE. "Cerrar sesión" vive
/// en el avatar de cada pantalla (`ProfileMenuButton`), no en la barra.
class ClienteShell extends ConsumerStatefulWidget {
  const ClienteShell({super.key});

  @override
  ConsumerState<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends ConsumerState<ClienteShell> {
  static const _screens = {
    ClienteTab.inicio: CatalogScreen(),
    ClienteTab.reservar: BookingScreen(),
    ClienteTab.reservas: MyReservationsScreen(),
    ClienteTab.vehiculos: VehiclesScreen(),
  };

  @override
  void initState() {
    super.initState();
    // Los controllers no son autoDispose: sin esto, tras cerrar sesión y
    // entrar con otra cuenta en el mismo dispositivo se veían las reservas
    // (y la pestaña) de la cuenta anterior hasta refrescar a mano.
    // (`ref` no puede usarse aún en initState: se va directo al container.)
    ProviderScope.containerOf(context, listen: false)
      ..invalidate(clienteTabProvider)
      ..invalidate(catalogControllerProvider)
      ..invalidate(bookingControllerProvider)
      ..invalidate(servicioElegidoProvider)
      ..invalidate(myReservationsControllerProvider);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(clienteTabProvider);
    return Scaffold(
      body: AnimatedSwitcher(
        duration: LavaderoMotion.normal,
        child: KeyedSubtree(key: ValueKey(tab), child: _screens[tab]!),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: (i) =>
            ref.read(clienteTabProvider.notifier).ir(ClienteTab.values[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: 'Reservar',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note_rounded),
            label: 'Mis reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car_rounded),
            label: 'Vehículos',
          ),
        ],
      ),
    );
  }
}
