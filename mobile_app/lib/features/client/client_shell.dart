import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/application/auth_controller.dart';
import 'booking/booking_screen.dart';
import 'catalog/catalog_screen.dart';
import 'reservations/presentation/my_reservations_screen.dart';
import 'vehicles/vehicles_screen.dart';

/// Shell de navegación para usuarios con rol CLIENTE.
class ClienteShell extends ConsumerStatefulWidget {
  const ClienteShell({super.key});

  @override
  ConsumerState<ClienteShell> createState() => _ClienteShellState();
}

class _ClienteShellState extends ConsumerState<ClienteShell> {
  int _index = 0;

  static const _screens = [
    CatalogScreen(),
    BookingScreen(),
    MyReservationsScreen(),
    VehiclesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          if (i == 4) {
            ref.read(authControllerProvider.notifier).logout();
            return;
          }
          setState(() => _index = i);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.local_car_wash_outlined),
            label: 'Catálogo',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: 'Reservar',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Mis reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            label: 'Vehículos',
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
