import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../client/catalog/application/catalog_controller.dart';
import '../../shared/widgets/profile_menu_button.dart';
import 'application/agenda_controller.dart';

/// Agenda del día para el empleado como línea de tiempo: columna de horas,
/// el lavado en curso y el siguiente destacados, y las acciones
/// iniciar/completar en cada tarjeta. Consume `/api/v1/agenda/reservas`
/// (vista de empleado). Reemplaza el antiguo placeholder "Turnos" — ver
/// docs/specs/002-agenda-reservas.md.
class ShiftsScreen extends ConsumerStatefulWidget {
  const ShiftsScreen({super.key});

  @override
  ConsumerState<ShiftsScreen> createState() => _ShiftsScreenState();
}

class _ShiftsScreenState extends ConsumerState<ShiftsScreen> {
  /// Reservas con una acción en vuelo (spinner solo en esa tarjeta).
  final _procesando = <String>{};

  Future<void> _accion(
    String reservaId,
    Future<void> Function(String) accion,
  ) async {
    setState(() => _procesando.add(reservaId));
    try {
      await accion(reservaId);
    } on ApiException catch (e) {
      // Antes la excepción escapaba sin capturar y el botón no daba
      // ninguna señal de que la acción había fallado.
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _procesando.remove(reservaId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agendaControllerProvider);
    final controller = ref.read(agendaControllerProvider.notifier);
    // Solo para mostrar el nombre del servicio (la reserva trae el id).
    final servicios = {
      for (final s in ref.watch(catalogControllerProvider).items) s.id: s,
    };
    final ahora = DateTime.now();
    final reservas = [...state.reservas]
      ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));
    final actual = reservas
        .where((r) => r.estado == ReservaEstado.enProgreso)
        .firstOrNull;
    final siguiente = reservas
        .where(
          (r) =>
              r.estado == ReservaEstado.pendiente &&
              r.fechaHoraFin.isAfter(ahora),
        )
        .firstOrNull;
    final fecha = Formato.fechaCorta(ahora);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.cargar,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              LavaderoSpacing.lg,
              LavaderoSpacing.md,
              LavaderoSpacing.lg,
              LavaderoSpacing.xl,
            ),
            children: [
              PageHeader(
                title: 'Agenda de hoy',
                description: fecha[0].toUpperCase() + fecha.substring(1),
                trailing: const ProfileMenuButton(),
              ),
              if (state.isLoading)
                const SkeletonList.inline(itemCount: 4)
              else if (state.errorMessage != null)
                ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: controller.cargar,
                )
              else if (reservas.isEmpty) ...[
                const SizedBox(height: LavaderoSpacing.xl),
                const EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'No hay reservas para hoy',
                  message:
                      'Cuando lleguen reservas a tu sucursal, aparecerán aquí.',
                ),
              ] else ...[
                FadeSlideIn(child: _Resumen(reservas: reservas)),
                const SizedBox(height: LavaderoSpacing.lg),
                for (var i = 0; i < reservas.length; i++)
                  FadeSlideIn(
                    index: i + 1,
                    child: _TimelineItem(
                      reserva: reservas[i],
                      servicio: servicios[reservas[i].servicioId],
                      esPrimero: i == 0,
                      esUltimo: i == reservas.length - 1,
                      destacado: reservas[i].id == actual?.id
                          ? _Destacado.ahora
                          : reservas[i].id == siguiente?.id
                          ? _Destacado.siguiente
                          : null,
                      procesando: _procesando.contains(reservas[i].id),
                      onIniciar: () =>
                          _accion(reservas[i].id, controller.iniciar),
                      onCompletar: () =>
                          _accion(reservas[i].id, controller.completar),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.reservas});

  final List<Reserva> reservas;

  int _contar(ReservaEstado e) => reservas.where((r) => r.estado == e).length;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _ResumenDato(
            valor: _contar(ReservaEstado.pendiente),
            etiqueta: 'Por atender',
            color: LavaderoColors.warning,
          ),
        ),
        const SizedBox(width: LavaderoSpacing.sm),
        Expanded(
          child: _ResumenDato(
            valor: _contar(ReservaEstado.enProgreso),
            etiqueta: 'En curso',
            color: scheme.primary,
          ),
        ),
        const SizedBox(width: LavaderoSpacing.sm),
        Expanded(
          child: _ResumenDato(
            valor: _contar(ReservaEstado.completada),
            etiqueta: 'Listas',
            color: LavaderoColors.success,
          ),
        ),
      ],
    );
  }
}

class _ResumenDato extends StatelessWidget {
  const _ResumenDato({
    required this.valor,
    required this.etiqueta,
    required this.color,
  });

  final int valor;
  final String etiqueta;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LavaderoCard(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.md,
        vertical: LavaderoSpacing.smd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: LavaderoSpacing.sm,
                height: LavaderoSpacing.sm,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: LavaderoSpacing.xs + LavaderoSpacing.xxs),
              Text(
                '$valor',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontFeatures: LavaderoTypography.tabular,
                ),
              ),
            ],
          ),
          Text(
            etiqueta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

enum _Destacado { ahora, siguiente }

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.reserva,
    required this.servicio,
    required this.esPrimero,
    required this.esUltimo,
    required this.destacado,
    required this.procesando,
    required this.onIniciar,
    required this.onCompletar,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final bool esPrimero;
  final bool esUltimo;
  final _Destacado? destacado;
  final bool procesando;
  final VoidCallback onIniciar;
  final VoidCallback onCompletar;

  static const double _columnaHora = LavaderoSizes.avatarLg;
  static const double _anchoRiel = LavaderoSpacing.lg;
  static const double _punto = LavaderoSpacing.smd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final inicio = reserva.fechaHoraInicio.toLocal();
    final fin = reserva.fechaHoraFin.toLocal();
    final cerrada =
        reserva.estado == ReservaEstado.completada ||
        reserva.estado == ReservaEstado.cancelada;
    final colorEstado = reserva.estado.colorDe(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _columnaHora,
            child: Padding(
              padding: const EdgeInsets.only(top: LavaderoSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Formato.hora(inicio),
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: destacado != null
                          ? scheme.primary
                          : cerrada
                          ? scheme.onSurfaceVariant
                          : scheme.onSurface,
                      fontFeatures: LavaderoTypography.tabular,
                    ),
                  ),
                  Text(
                    Formato.hora(fin),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontFeatures: LavaderoTypography.tabular,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: _anchoRiel,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: esPrimero ? LavaderoSpacing.md + _punto / 2 : 0,
                  bottom: esUltimo ? null : 0,
                  height: esUltimo ? LavaderoSpacing.md + _punto / 2 : null,
                  child: Container(
                    width: LavaderoSpacing.xxs,
                    color: scheme.outlineVariant,
                  ),
                ),
                Positioned(
                  top: LavaderoSpacing.md + LavaderoSpacing.xxs,
                  child: Container(
                    width: _punto,
                    height: _punto,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorEstado,
                      border: Border.all(
                        color: scheme.surface,
                        width: LavaderoSpacing.xxs,
                      ),
                      boxShadow: destacado == null
                          ? null
                          : LavaderoShadows.glow(colorEstado),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                bottom: LavaderoSpacing.smd,
              ),
              child: AnimatedOpacity(
                duration: LavaderoMotion.normal,
                opacity: cerrada ? 0.72 : 1,
                child: destacado == _Destacado.ahora
                    ? _TarjetaEnCurso(
                        reserva: reserva,
                        servicio: servicio,
                        procesando: procesando,
                        onCompletar: onCompletar,
                      )
                    : _TarjetaReserva(
                        reserva: reserva,
                        servicio: servicio,
                        esSiguiente: destacado == _Destacado.siguiente,
                        cerrada: cerrada,
                        procesando: procesando,
                        onIniciar: onIniciar,
                        onCompletar: onCompletar,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaReserva extends StatelessWidget {
  const _TarjetaReserva({
    required this.reserva,
    required this.servicio,
    required this.esSiguiente,
    required this.cerrada,
    required this.procesando,
    required this.onIniciar,
    required this.onCompletar,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final bool esSiguiente;
  final bool cerrada;
  final bool procesando;
  final VoidCallback onIniciar;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LavaderoCard(
      elevated: !cerrada,
      color: esSiguiente
          ? scheme.primaryContainer.withValues(alpha: 0.55)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (esSiguiente) ...[
            Text(
              'SIGUIENTE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: LavaderoSpacing.xs),
          ],
          Row(
            children: [
              Expanded(
                child: _ServicioResumen(
                  reserva: reserva,
                  servicio: servicio,
                  color: scheme.onSurface,
                  secundario: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: LavaderoSpacing.sm),
              ReservaEstadoBadge(estado: reserva.estado),
            ],
          ),
          if (reserva.estado == ReservaEstado.pendiente ||
              reserva.estado == ReservaEstado.enProgreso) ...[
            const SizedBox(height: LavaderoSpacing.smd),
            Align(
              alignment: Alignment.centerRight,
              child: reserva.estado == ReservaEstado.pendiente
                  ? _BotonAccion(
                      label: 'Iniciar',
                      icon: Icons.play_arrow_rounded,
                      tonal: !esSiguiente,
                      procesando: procesando,
                      onPressed: onIniciar,
                    )
                  : _BotonAccion(
                      label: 'Completar',
                      icon: Icons.check_rounded,
                      procesando: procesando,
                      onPressed: onCompletar,
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

/// El lavado que se está haciendo ahora: tarjeta héroe con degradado.
class _TarjetaEnCurso extends StatelessWidget {
  const _TarjetaEnCurso({
    required this.reserva,
    required this.servicio,
    required this.procesando,
    required this.onCompletar,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final bool procesando;
  final VoidCallback onCompletar;

  @override
  Widget build(BuildContext context) {
    return LavaderoCard(
      gradient: LavaderoGradients.brandStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: GlassPill(
              label: 'Ahora · En progreso',
              icon: Icons.local_car_wash_rounded,
            ),
          ),
          const SizedBox(height: LavaderoSpacing.smd),
          _ServicioResumen(
            reserva: reserva,
            servicio: servicio,
            color: LavaderoColors.white,
            secundario: LavaderoColors.onBrandMuted,
            sobreDegradado: true,
          ),
          const SizedBox(height: LavaderoSpacing.smd),
          Align(
            alignment: Alignment.centerRight,
            child: _BotonAccion(
              label: 'Completar',
              icon: Icons.check_rounded,
              procesando: procesando,
              onPressed: onCompletar,
              sobreDegradado: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicioResumen extends StatelessWidget {
  const _ServicioResumen({
    required this.reserva,
    required this.servicio,
    required this.color,
    required this.secundario,
    this.sobreDegradado = false,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final Color color;
  final Color secundario;
  final bool sobreDegradado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconBadge(
          icon: servicio?.icono ?? Icons.local_car_wash_rounded,
          color: sobreDegradado
              ? LavaderoColors.white
              : servicio?.colorAcento ?? theme.colorScheme.primary,
        ),
        const SizedBox(width: LavaderoSpacing.smd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                servicio?.nombre ?? 'Reserva',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(color: color),
              ),
              Text(
                '${reserva.duracionEstimadaMinutos} min · '
                '${Formato.moneda(reserva.precio, reserva.moneda)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secundario,
                  fontFeatures: LavaderoTypography.tabular,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.label,
    required this.icon,
    required this.procesando,
    required this.onPressed,
    this.tonal = false,
    this.sobreDegradado = false,
  });

  final String label;
  final IconData icon;
  final bool procesando;
  final VoidCallback onPressed;
  final bool tonal;
  final bool sobreDegradado;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = sobreDegradado
        ? LavaderoColors.ocean
        : tonal
        ? scheme.onPrimaryContainer
        : scheme.onPrimary;
    final style = FilledButton.styleFrom(
      minimumSize: const Size(0, LavaderoSizes.minTapTarget),
      backgroundColor: sobreDegradado
          ? LavaderoColors.white
          : tonal
          ? scheme.primaryContainer
          : scheme.primary,
      foregroundColor: foreground,
      disabledBackgroundColor: sobreDegradado
          ? LavaderoColors.white.withValues(alpha: 0.8)
          : null,
    );
    return FilledButton.icon(
      onPressed: procesando ? null : onPressed,
      style: style,
      icon: procesando
          ? InlineSpinner(
 size: LavaderoSizes.iconSm,
 color: sobreDegradado ? LavaderoColors.ocean : scheme.primary,
 )
          : Icon(icon, size: LavaderoSizes.iconMd),
      label: Text(label),
    );
  }
}
