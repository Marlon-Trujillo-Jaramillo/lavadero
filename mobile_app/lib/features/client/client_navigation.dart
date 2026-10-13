import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pestañas del `ClienteShell`. El shell es dueño de la navegación; las
/// pantallas solo piden "ir a" una pestaña (p. ej. tocar un servicio en el
/// inicio abre "Reservar") a través de este controller.
enum ClienteTab { inicio, reservar, reservas, vehiculos }

final clienteTabProvider = NotifierProvider<ClienteTabController, ClienteTab>(
  ClienteTabController.new,
);

class ClienteTabController extends Notifier<ClienteTab> {
  @override
  ClienteTab build() => ClienteTab.inicio;

  void ir(ClienteTab tab) => state = tab;
}
