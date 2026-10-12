import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../application/tenant_selection_controller.dart';

/// Pantalla pública: buscar/elegir el lavadero (tenant) antes de login o
/// registro. Consume `GET /api/v1/tenants?query=`.
class TenantSelectionScreen extends ConsumerStatefulWidget {
  const TenantSelectionScreen({super.key});

  @override
  ConsumerState<TenantSelectionScreen> createState() =>
      _TenantSelectionScreenState();
}

class _TenantSelectionScreenState
    extends ConsumerState<TenantSelectionScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantSelectionControllerProvider);
    final controller = ref.read(tenantSelectionControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Elige tu lavadero')),
      body: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Buscar lavadero por nombre',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: controller.search,
            ),
            const SizedBox(height: LavaderoSpacing.md),
            if (state.errorMessage != null)
              ErrorBanner(message: state.errorMessage!),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.only(top: LavaderoSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: _TenantResultsList(
                  results: state.results,
                  query: state.query,
                  onSelected: (tenant) {
                    controller.select(tenant);
                    context.push('/login');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TenantResultsList extends StatelessWidget {
  const _TenantResultsList({
    required this.results,
    required this.query,
    required this.onSelected,
  });

  final List<TenantSummary> results;
  final String query;
  final ValueChanged<TenantSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Escribe el nombre de tu lavadero para buscarlo.'),
      );
    }
    if (results.isEmpty) {
      return const Center(child: Text('No se encontraron lavaderos.'));
    }
    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final tenant = results[index];
        return ListTile(
          leading: const Icon(Icons.local_car_wash_outlined),
          title: Text(tenant.nombre),
          subtitle: Text(tenant.slug),
          onTap: () => onSelected(tenant),
        );
      },
    );
  }
}
