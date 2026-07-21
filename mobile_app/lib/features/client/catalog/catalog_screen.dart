import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'application/catalog_controller.dart';

/// Catálogo de servicios del lavadero, solo lectura — lo que el cliente ve
/// antes de reservar. Consume `/api/v1/catalogo/servicios/activos`.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catalogControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de servicios')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(catalogControllerProvider.notifier).cargar(),
        child: Padding(
          padding: const EdgeInsets.all(LavaderoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: LavaderoSpacing.md),
                  child: ErrorBanner(message: state.errorMessage!),
                ),
              if (state.isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (state.items.isEmpty)
                ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.only(top: LavaderoSpacing.xl),
                      child: Center(
                        child: Text('Este lavadero todavía no publicó servicios.'),
                      ),
                    ),
                  ],
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: state.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return ListTile(
                        leading: const Icon(Icons.local_car_wash_outlined),
                        title: Text(item.nombre),
                        subtitle: item.descripcion == null || item.descripcion!.isEmpty
                            ? Text('${item.duracionEstimadaMinutos} min')
                            : Text(
                                '${item.descripcion}\n${item.duracionEstimadaMinutos} min',
                              ),
                        isThreeLine: item.descripcion != null && item.descripcion!.isNotEmpty,
                        trailing: Text(
                          '\$${item.precio.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
