import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/router/app_routes.dart';
import '../application/tenant_selection_controller.dart';

/// Pantalla pública: buscar/elegir el lavadero (tenant) antes de login o
/// registro. Consume `GET /api/v1/tenants?query=`.
class TenantSelectionScreen extends ConsumerStatefulWidget {
  const TenantSelectionScreen({super.key});

  @override
  ConsumerState<TenantSelectionScreen> createState() =>
      _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends ConsumerState<TenantSelectionScreen> {
  static const _debounce = Duration(milliseconds: 300);

  final _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Antes se disparaba una petición por cada tecla; ahora se espera a que
  /// el usuario haga una pausa corta.
  void _onChanged(String value) {
    setState(() {}); // Muestra/oculta el botón de limpiar.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      _debounce,
      () => ref.read(tenantSelectionControllerProvider.notifier).search(value),
    );
  }

  void _clear() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {});
    ref.read(tenantSelectionControllerProvider.notifier).search('');
  }

  void _select(TenantSummary tenant) {
    FocusScope.of(context).unfocus();
    ref.read(tenantSelectionControllerProvider.notifier).select(tenant);
    context.push(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tenantSelectionControllerProvider);
    final controller = ref.read(tenantSelectionControllerProvider.notifier);

    return AuthLayout(
      title: 'Encuentra tu lavadero',
      subtitle: 'Búscalo por nombre para reservar o entrar a tu turno.',
      brandHeadline: 'Tu auto,\nimpecable.',
      brandMessage:
          'Reserva tu lavado en segundos y sigue cada paso desde el celular.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Ej. Lavadero Central',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpiar',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _clear,
                    ),
            ),
            onChanged: _onChanged,
            onSubmitted: (value) {
              _debounceTimer?.cancel();
              controller.search(value);
            },
          ),
          const SizedBox(height: LavaderoSpacing.lg),
          if (state.errorMessage != null) ...[
            ErrorBanner(
              message: state.errorMessage!,
              onRetry: () => controller.search(state.query),
            ),
            const SizedBox(height: LavaderoSpacing.md),
          ],
          AnimatedSwitcher(
            duration: LavaderoMotion.normal,
            child: _Results(
              key: ValueKey(
                '${state.isLoading}-${state.query}-${state.results.length}',
              ),
              state: state,
              onSelected: _select,
            ),
          ),
        ],
      ),
    );
  }
}

class _Results extends StatelessWidget {
  const _Results({super.key, required this.state, required this.onSelected});

  final TenantSelectionState state;
  final ValueChanged<TenantSummary> onSelected;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) return const SkeletonList.inline();
    if (state.query.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.local_car_wash_outlined,
        title: 'Busca tu lavadero',
        message: 'Escribe el nombre de tu lavadero para buscarlo.',
      );
    }
    if (state.results.isEmpty) {
      if (state.errorMessage != null) return const SizedBox.shrink();
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No se encontraron lavaderos',
        message: 'Revisa el nombre o prueba con otra palabra.',
      );
    }
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          state.results.length == 1
              ? '1 resultado'
              : '${state.results.length} resultados',
          style: textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: LavaderoSpacing.sm),
        for (var i = 0; i < state.results.length; i++) ...[
          FadeSlideIn(
            index: i,
            child: _TenantCard(
              tenant: state.results[i],
              onTap: () => onSelected(state.results[i]),
            ),
          ),
          const SizedBox(height: LavaderoSpacing.sm),
        ],
      ],
    );
  }
}

class _TenantCard extends StatelessWidget {
  const _TenantCard({required this.tenant, required this.onTap});

  final TenantSummary tenant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LavaderoCard(
      onTap: onTap,
      child: Row(
        children: [
          AvatarInitials(name: tenant.nombre, size: LavaderoSizes.avatarLg),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tenant.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: LavaderoSpacing.xxs),
                Text(
                  '@${tenant.slug}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: LavaderoSizes.iconSm,
            color: scheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
