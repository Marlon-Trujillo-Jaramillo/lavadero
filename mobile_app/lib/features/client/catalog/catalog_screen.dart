import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../../auth/application/auth_controller.dart';
import '../../shared/user_display.dart';
import '../../shared/widgets/profile_menu_button.dart';
import '../booking/application/booking_controller.dart';
import '../client_navigation.dart';
import '../reservations/application/my_reservations_controller.dart';
import '../reservations/application/reservas_agrupadas.dart';
import '../widgets/proxima_reserva_hero.dart';
import '../widgets/servicio_card.dart';
import 'application/catalog_controller.dart';

/// Inicio del cliente: saludo, su próxima reserva (derivada de "Mis
/// reservas") y el catálogo de servicios activos como grilla de tarjetas.
/// Tocar un servicio abre "Reservar" con ese servicio ya elegido. Consume
/// `/api/v1/catalogo/servicios/activos` y `/api/v1/agenda/reservas/mias`.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  static const _columnas = 2;

  Future<void> _refrescar(WidgetRef ref) => Future.wait([
    ref.read(catalogControllerProvider.notifier).cargar(),
    ref.read(myReservationsControllerProvider.notifier).cargar(),
  ]);

  void _reservar(WidgetRef ref, ServiceItem? servicio) {
    ref.read(servicioElegidoProvider.notifier).elegir(servicio);
    ref.read(clienteTabProvider.notifier).ir(ClienteTab.reservar);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final catalog = ref.watch(catalogControllerProvider);
    final reservas = ref.watch(myReservationsControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final tenantName = ref.watch(selectedTenantNameProvider);
    final nombre = authState is AuthAuthenticated
        ? authState.user.nombreCorto
        : null;
    final ahora = DateTime.now();
    final proxima = reservas.proxima(ahora);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _refrescar(ref),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LavaderoSpacing.lg,
              LavaderoSpacing.md,
              LavaderoSpacing.lg,
              LavaderoSpacing.xl,
            ),
            children: [
              Row(
                children: [
                  // Expanded (no Spacer): el wordmark usa `Flexible` y
                  // necesita ancho acotado para recortar nombres largos.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: LavaderoLogo(
                        size: LavaderoSizes.iconXl,
                        showWordmark: true,
                        label: tenantName ?? 'Lavadero',
                      ),
                    ),
                  ),
                  const SizedBox(width: LavaderoSpacing.md),
                  const ProfileMenuButton(),
                ],
              ),
              const SizedBox(height: LavaderoSpacing.lg),
              FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre == null ? 'Hola 👋' : 'Hola, $nombre 👋',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: LavaderoSpacing.xs),
                    Text(
                      'Tu auto merece brillar',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: LavaderoSpacing.lg),
              FadeSlideIn(
                index: 1,
                child: AnimatedSwitcher(
                  duration: LavaderoMotion.normal,
                  child: reservas.isLoading && reservas.reservas.isEmpty
                      ? const _HeroSkeleton()
                      : proxima != null
                      ? ProximaReservaHero(
                          key: ValueKey(proxima.id),
                          reserva: proxima,
                          servicio: reservas.servicios[proxima.servicioId],
                          ahora: ahora,
                          onTap: () => ref
                              .read(clienteTabProvider.notifier)
                              .ir(ClienteTab.reservas),
                        )
                      : ReservarCtaHero(onReservar: () => _reservar(ref, null)),
                ),
              ),
              const SizedBox(height: LavaderoSpacing.xl),
              SectionHeader(
                title: 'Servicios',
                subtitle: catalog.items.isEmpty
                    ? null
                    : 'Toca uno para reservarlo',
              ),
              if (catalog.errorMessage != null) ...[
                ErrorBanner(
                  message: catalog.errorMessage!,
                  onRetry: ref.read(catalogControllerProvider.notifier).cargar,
                ),
                const SizedBox(height: LavaderoSpacing.md),
              ],
              if (catalog.isLoading && catalog.items.isEmpty)
                const _GridSkeleton(columnas: _columnas)
              else if (catalog.items.isEmpty && catalog.errorMessage == null)
                const EmptyState(
                  icon: Icons.local_car_wash_outlined,
                  title: 'Aún no hay servicios',
                  message: 'Este lavadero todavía no publicó servicios.',
                )
              else
                _ServiciosGrid(
                  servicios: catalog.items,
                  columnas: _columnas,
                  onTap: (servicio) => _reservar(ref, servicio),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grilla de N columnas con filas de altura igual (la tarjeta más alta de
/// cada fila manda), sin `GridView` + `childAspectRatio` fijo que recorta
/// el texto con fuentes grandes.
class _ServiciosGrid extends StatelessWidget {
  const _ServiciosGrid({
    required this.servicios,
    required this.columnas,
    required this.onTap,
  });

  final List<ServiceItem> servicios;
  final int columnas;
  final ValueChanged<ServiceItem> onTap;

  @override
  Widget build(BuildContext context) {
    final filas = <List<ServiceItem>>[
      for (var i = 0; i < servicios.length; i += columnas)
        servicios.sublist(i, (i + columnas).clamp(0, servicios.length)),
    ];
    return Column(
      children: [
        for (var f = 0; f < filas.length; f++) ...[
          if (f > 0) const SizedBox(height: LavaderoSpacing.smd),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columnas; c++) ...[
                  if (c > 0) const SizedBox(width: LavaderoSpacing.smd),
                  Expanded(
                    child: c < filas[f].length
                        ? FadeSlideIn(
                            index: f * columnas + c + 2,
                            child: ServicioCard(
                              servicio: filas[f][c],
                              onTap: () => onTap(filas[f][c]),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Skeleton(
      height: LavaderoSizes.avatarLg * 2 + LavaderoSpacing.xl,
      radius: LavaderoRadii.lg,
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton({required this.columnas});

  final int columnas;

  @override
  Widget build(BuildContext context) {
    return SkeletonScope(
      child: Column(
        children: [
          for (var f = 0; f < 2; f++) ...[
            if (f > 0) const SizedBox(height: LavaderoSpacing.smd),
            Row(
              children: [
                for (var c = 0; c < columnas; c++) ...[
                  if (c > 0) const SizedBox(width: LavaderoSpacing.smd),
                  const Expanded(
                    child: Skeleton(
                      height: LavaderoSizes.avatarLg * 2 + LavaderoSpacing.lg,
                      radius: LavaderoRadii.lg,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
