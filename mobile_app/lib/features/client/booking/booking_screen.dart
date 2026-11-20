import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../shared/widgets/profile_menu_button.dart';
import '../../shared/widgets/success_check.dart';
import '../client_navigation.dart';
import '../reservations/application/my_reservations_controller.dart';
import '../vehicles/vehicles_screen.dart';
import 'application/booking_controller.dart';

/// Reserva de un servicio del catálogo, en una sucursal, para un horario, en
/// pasos: servicio → día → hora → sucursal → confirmar. Consume
/// `/api/v1/agenda/reservas` (vía `SchedulingRepository`) y el catálogo de
/// servicios activos.
///
/// Los horarios se ofrecen en una grilla fija ([_apertura]–[_cierre] cada
/// [_intervaloMinutos]); el backend sigue siendo quien valida capacidad y
/// solapes (no hay endpoint de disponibilidad todavía).
class BookingScreen extends ConsumerStatefulWidget {
  const BookingScreen({super.key});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

const _apertura = 8;
const _cierre = 18;
const _intervaloMinutos = 30;
const _diasVisibles = 7;

/// Margen mínimo para reservar "hoy" (no ofrecer un horario que empieza ya).
const _anticipacion = Duration(minutes: 30);

DateTime _soloFecha(DateTime d) => DateTime(d.year, d.month, d.day);

List<DateTime> _horariosDe(DateTime dia, DateTime ahora) => [
  for (
    var minuto = _apertura * 60;
    minuto < _cierre * 60;
    minuto += _intervaloMinutos
  )
    DateTime(dia.year, dia.month, dia.day, 0, minuto),
].where((h) => h.isAfter(ahora.add(_anticipacion))).toList();

class _BookingScreenState extends ConsumerState<BookingScreen> {
  late DateTime _dia;
  DateTime? _horario;
  Sucursal? _sucursal;

  /// Vehículo elegido. Mientras el cliente no elija, se propone el más
  /// reciente; "Sin vehículo" es una elección válida (null).
  String? _vehiculoId;
  bool _vehiculoElegido = false;

  @override
  void initState() {
    super.initState();
    final ahora = DateTime.now();
    // Si ya no quedan horarios hoy, se arranca en mañana.
    _dia = _horariosDe(_soloFecha(ahora), ahora).isEmpty
        ? _soloFecha(ahora).add(const Duration(days: 1))
        : _soloFecha(ahora);
  }

  String? _vehiculoEfectivo(List<Vehiculo> vehiculos) =>
      _vehiculoElegido ? _vehiculoId : vehiculos.firstOrNull?.id;

  void _elegirVehiculo(String? id) => setState(() {
    _vehiculoId = id;
    _vehiculoElegido = true;
  });

  Future<void> _agregarVehiculo() async {
    final nuevo = await abrirFormularioVehiculo(context);
    if (nuevo == null || !mounted) return;
    ref.read(bookingControllerProvider.notifier).agregarVehiculo(nuevo);
    _elegirVehiculo(nuevo.id);
  }

  Sucursal? _sucursalEfectiva(List<Sucursal> sucursales) =>
      _sucursal ?? (sucursales.length == 1 ? sucursales.first : null);

  void _cotizar(ServiceItem? servicio, DateTime? horario) {
    ref
        .read(bookingControllerProvider.notifier)
        .cotizar(servicioId: servicio?.id, fechaHoraInicio: horario);
  }

  void _confirmar(
    ServiceItem servicio,
    Sucursal sucursal,
    DateTime horario,
    String? vehiculoId,
  ) {
    ref
        .read(bookingControllerProvider.notifier)
        .reservar(
          sucursalId: sucursal.id,
          servicioId: servicio.id,
          fechaHoraInicio: horario,
          vehiculoId: vehiculoId,
        );
  }

  void _reiniciar() {
    ref.read(bookingControllerProvider.notifier).reiniciar();
    ref.read(servicioElegidoProvider.notifier).elegir(null);
    setState(() {
      _horario = null;
      _vehiculoElegido = false;
    });
  }

  void _verMisReservas() {
    _reiniciar();
    ref.read(clienteTabProvider.notifier).ir(ClienteTab.reservas);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);
    final servicio = ref.watch(servicioElegidoProvider);
    final controller = ref.read(bookingControllerProvider.notifier);

    // El precio depende del servicio y la hora (precios por horario, cupón).
    ref.listen(servicioElegidoProvider, (previous, next) {
      if (previous?.id != next?.id) _cotizar(next, _horario);
    });

    // Al confirmar, "Mis reservas" (y el héroe del inicio) se refrescan.
    ref.listen(bookingControllerProvider, (previous, next) {
      if (previous?.reservaCreada == null && next.reservaCreada != null) {
        ref.read(myReservationsControllerProvider.notifier).cargar();
      }
    });

    final creada = state.reservaCreada;
    if (creada != null) {
      return Scaffold(
        body: SafeArea(
          child: _ConfirmacionReserva(
            reserva: creada,
            servicio:
                state.servicios
                    .where((s) => s.id == creada.servicioId)
                    .firstOrNull ??
                servicio,
            sucursal: state.sucursales
                .where((s) => s.id == creada.sucursalId)
                .firstOrNull,
            onVerReservas: _verMisReservas,
            onReservarOtra: _reiniciar,
          ),
        ),
      );
    }

    final sucursal = _sucursalEfectiva(state.sucursales);
    final vehiculoId = _vehiculoEfectivo(state.vehiculos);
    final ahora = DateTime.now();
    final horarios = _horariosDe(_dia, ahora);
    final puedeReservar = !state.isLoading && state.servicios.isNotEmpty;

    return Scaffold(
      bottomNavigationBar: puedeReservar
          ? _ResumenBar(
              servicio: servicio,
              horario: _horario,
              cotizacion: state.cotizacion,
              isSubmitting: state.isSubmitting,
              onConfirmar:
                  servicio != null && sucursal != null && _horario != null
                  ? () => _confirmar(servicio, sucursal, _horario!, vehiculoId)
                  : null,
            )
          : null,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            LavaderoSpacing.lg,
            LavaderoSpacing.md,
            LavaderoSpacing.lg,
            LavaderoSpacing.xl,
          ),
          children: [
            const PageHeader(
              title: 'Reservar',
              description: 'Elige servicio, día y hora. Sin filas.',
              trailing: ProfileMenuButton(),
            ),
            if (state.errorMessage != null) ...[
              ErrorBanner(
                message: state.errorMessage!,
                onRetry: state.servicios.isEmpty
                    ? controller.cargarOpciones
                    : null,
              ),
              const SizedBox(height: LavaderoSpacing.lg),
            ],
            if (state.isLoading)
              const SkeletonList.inline(itemCount: 4)
            else if (state.servicios.isEmpty) ...[
              if (state.errorMessage == null)
                const EmptyState(
                  icon: Icons.local_car_wash_outlined,
                  title: 'Aún no hay servicios',
                  message:
                      'Este lavadero todavía no publicó servicios para '
                      'reservar.',
                ),
            ] else ...[
              _Paso(
                numero: 1,
                titulo: 'Servicio',
                completo: servicio != null,
                child: AnimatedSwitcher(
                  duration: LavaderoMotion.normal,
                  child: servicio != null
                      ? _ServicioElegido(
                          key: ValueKey(servicio.id),
                          servicio: servicio,
                          onCambiar: () => ref
                              .read(servicioElegidoProvider.notifier)
                              .elegir(null),
                        )
                      : _ServicioOpciones(
                          servicios: state.servicios,
                          onElegir: ref
                              .read(servicioElegidoProvider.notifier)
                              .elegir,
                        ),
                ),
              ),
              _Paso(
                numero: 2,
                titulo: 'Día',
                completo: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      for (var i = 0; i < _diasVisibles; i++) ...[
                        if (i > 0) const SizedBox(width: LavaderoSpacing.sm),
                        _DiaChip(
                          dia: _soloFecha(ahora).add(Duration(days: i)),
                          ahora: ahora,
                          seleccionado:
                              _soloFecha(ahora).add(Duration(days: i)) == _dia,
                          onTap: () {
                            setState(() {
                              _dia = _soloFecha(ahora).add(Duration(days: i));
                              _horario = null;
                            });
                            _cotizar(servicio, null);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _Paso(
                numero: 3,
                titulo: 'Hora',
                completo: _horario != null,
                child: horarios.isEmpty
                    ? Text(
                        'Ya no quedan horarios este día. Prueba con otro.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Wrap(
                        spacing: LavaderoSpacing.sm,
                        runSpacing: LavaderoSpacing.sm,
                        children: [
                          for (final h in horarios)
                            ChoiceChip(
                              label: Text(Formato.hora(h)),
                              showCheckmark: false,
                              selected: h == _horario,
                              onSelected: (_) {
                                setState(() => _horario = h);
                                _cotizar(servicio, h);
                              },
                            ),
                        ],
                      ),
              ),
              if (state.sucursales.length > 1)
                _Paso(
                  numero: 4,
                  titulo: 'Sucursal',
                  completo: sucursal != null,
                  child: Column(
                    children: [
                      for (final s in state.sucursales) ...[
                        _SucursalOpcion(
                          sucursal: s,
                          seleccionada: s.id == sucursal?.id,
                          onTap: () => setState(() => _sucursal = s),
                        ),
                        const SizedBox(height: LavaderoSpacing.sm),
                      ],
                    ],
                  ),
                )
              else if (sucursal != null)
                _SucursalUnica(sucursal: sucursal),
              _Paso(
                numero: state.sucursales.length > 1 ? 5 : 4,
                titulo: 'Vehículo (opcional)',
                completo: vehiculoId != null,
                child: _VehiculoOpciones(
                  vehiculos: state.vehiculos,
                  seleccionadoId: vehiculoId,
                  onElegir: _elegirVehiculo,
                  onAgregar: _agregarVehiculo,
                ),
              ),
              _Paso(
                numero: state.sucursales.length > 1 ? 6 : 5,
                titulo: 'Cupón (opcional)',
                completo: state.cupon != null,
                child: _CuponPaso(
                  cupon: state.cupon,
                  error: state.cuponError,
                  isAplicando: state.isAplicandoCupon,
                  // El backend valida el cupón contra un servicio y una hora.
                  habilitado: servicio != null && _horario != null,
                  descuento: state.cupon != null &&
                          state.cotizacion?.tieneDescuento == true
                      ? state.cotizacion
                      : null,
                  onAplicar: (codigo) => controller.aplicarCupon(
                    codigo: codigo,
                    servicioId: servicio!.id,
                    fechaHoraInicio: _horario!,
                  ),
                  onQuitar: () => controller.quitarCupon(
                    servicioId: servicio?.id,
                    fechaHoraInicio: _horario,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un paso del flujo: número (o check si ya está completo) + título.
class _Paso extends StatelessWidget {
  const _Paso({
    required this.numero,
    required this.titulo,
    required this.completo,
    required this.child,
  });

  final int numero;
  final String titulo;
  final bool completo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: LavaderoMotion.normal,
                curve: LavaderoMotion.emphasized,
                width: LavaderoSizes.iconLg,
                height: LavaderoSizes.iconLg,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completo
                      ? LavaderoColors.success
                      : scheme.primaryContainer,
                ),
                child: completo
                    ? const Icon(
                        Icons.check_rounded,
                        size: LavaderoSizes.iconSm,
                        color: LavaderoColors.white,
                      )
                    : Text(
                        '$numero',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
              ),
              const SizedBox(width: LavaderoSpacing.sm + LavaderoSpacing.xxs),
              Text(titulo, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _ServicioElegido extends StatelessWidget {
  const _ServicioElegido({
    super.key,
    required this.servicio,
    required this.onCambiar,
  });

  final ServiceItem servicio;
  final VoidCallback onCambiar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LavaderoCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
      child: Row(
        children: [
          IconBadge(
            icon: servicio.icono,
            color: servicio.colorAcento,
            size: LavaderoSizes.avatarLg,
          ),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(servicio.nombre, style: theme.textTheme.titleMedium),
                const SizedBox(height: LavaderoSpacing.xxs),
                Text(
                  '${servicio.duracionTexto} · ${servicio.precioTexto}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontFeatures: LavaderoTypography.tabular,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onCambiar, child: const Text('Cambiar')),
        ],
      ),
    );
  }
}

class _ServicioOpciones extends StatelessWidget {
  const _ServicioOpciones({required this.servicios, required this.onElegir});

  final List<ServiceItem> servicios;
  final ValueChanged<ServiceItem> onElegir;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        for (var i = 0; i < servicios.length; i++) ...[
          if (i > 0) const SizedBox(height: LavaderoSpacing.sm),
          FadeSlideIn(
            index: i,
            child: LavaderoCard(
              onTap: () => onElegir(servicios[i]),
              child: Row(
                children: [
                  IconBadge(
                    icon: servicios[i].icono,
                    color: servicios[i].colorAcento,
                  ),
                  const SizedBox(width: LavaderoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          servicios[i].nombre,
                          style: theme.textTheme.titleSmall,
                        ),
                        if (servicios[i].descripcion?.isNotEmpty ?? false)
                          Text(
                            servicios[i].descripcion!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        Text(
                          servicios[i].duracionTexto,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: LavaderoSpacing.sm),
                  Text(
                    servicios[i].precioTexto,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: scheme.primary,
                      fontFeatures: LavaderoTypography.tabular,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DiaChip extends StatelessWidget {
  const _DiaChip({
    required this.dia,
    required this.ahora,
    required this.seleccionado,
    required this.onTap,
  });

  final DateTime dia;
  final DateTime ahora;
  final bool seleccionado;
  final VoidCallback onTap;

  static const double _ancho = LavaderoSizes.avatarLg + LavaderoSpacing.sm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // `fechaCorta` = "lun 12 oct": se reutiliza para día de semana y mes.
    final partes = Formato.fechaCorta(dia).split(' ');
    final relativo = Formato.diaRelativo(dia, ahora: ahora);
    final arriba = relativo == 'Hoy' || relativo == 'Mañana'
        ? relativo
        : partes.first;
    final principal = seleccionado ? LavaderoColors.white : scheme.onSurface;
    final secundario = seleccionado
        ? LavaderoColors.onBrandMuted
        : scheme.onSurfaceVariant;
    return Pressable(
      onTap: onTap,
      selected: seleccionado,
      semanticLabel: Formato.fechaCorta(dia),
      borderRadius: BorderRadius.circular(LavaderoRadii.md),
      child: AnimatedContainer(
        duration: LavaderoMotion.normal,
        curve: LavaderoMotion.emphasized,
        width: _ancho,
        padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.smd),
        decoration: BoxDecoration(
          gradient: seleccionado ? LavaderoGradients.brandStrong : null,
          color: seleccionado ? null : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(LavaderoRadii.md),
          border: Border.all(
            color: seleccionado
                ? LavaderoColors.transparent
                : scheme.outlineVariant,
          ),
          boxShadow: seleccionado
              ? LavaderoShadows.glow(LavaderoColors.ocean)
              : null,
        ),
        child: Column(
          children: [
            Text(
              arriba,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(color: secundario),
            ),
            const SizedBox(height: LavaderoSpacing.xxs),
            Text(
              '${dia.day}',
              style: theme.textTheme.titleLarge?.copyWith(
                color: principal,
                fontFeatures: LavaderoTypography.tabular,
              ),
            ),
            Text(
              partes.last,
              style: theme.textTheme.labelSmall?.copyWith(color: secundario),
            ),
          ],
        ),
      ),
    );
  }
}

class _SucursalOpcion extends StatelessWidget {
  const _SucursalOpcion({
    required this.sucursal,
    required this.seleccionada,
    required this.onTap,
  });

  final Sucursal sucursal;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return LavaderoCard(
      onTap: onTap,
      color: seleccionada
          ? scheme.primaryContainer.withValues(alpha: 0.5)
          : null,
      child: Row(
        children: [
          const IconBadge(icon: Icons.storefront_rounded),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sucursal.nombre, style: theme.textTheme.titleSmall),
                if (sucursal.direccion?.isNotEmpty ?? false)
                  Text(
                    sucursal.direccion!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: LavaderoMotion.fast,
            child: Icon(
              seleccionada
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(seleccionada),
              color: seleccionada ? scheme.primary : scheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

/// Con una sola sucursal no hay nada que elegir: solo se informa dónde.
class _SucursalUnica extends StatelessWidget {
  const _SucursalUnica({required this.sucursal});

  final Sucursal sucursal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(
          Icons.place_outlined,
          size: LavaderoSizes.iconMd,
          color: scheme.onSurfaceVariant,
        ),
        const SizedBox(width: LavaderoSpacing.sm),
        Expanded(
          child: Text(
            [
              sucursal.nombre,
              if (sucursal.direccion?.isNotEmpty ?? false) sucursal.direccion!,
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra fija inferior: total + cuándo + botón de confirmar.
class _ResumenBar extends StatelessWidget {
  const _ResumenBar({
    required this.servicio,
    required this.horario,
    required this.cotizacion,
    required this.isSubmitting,
    required this.onConfirmar,
  });

  final ServiceItem? servicio;
  final DateTime? horario;
  final Cotizacion? cotizacion;
  final bool isSubmitting;
  final VoidCallback? onConfirmar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final conDescuento = cotizacion?.tieneDescuento == true ? cotizacion : null;
    final detalle = horario == null
        ? 'Elige día y hora'
        : conDescuento != null
        ? conDescuento.promocionNombre!
        : '${Formato.diaRelativo(horario!)} · ${Formato.hora(horario!)}';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LavaderoSpacing.lg,
          LavaderoSpacing.smd,
          LavaderoSpacing.lg,
          LavaderoSpacing.smd,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: LavaderoSpacing.sm,
                    children: [
                      Text(
                        conDescuento != null
                            ? Formato.moneda(
                                conDescuento.precioFinal,
                                conDescuento.moneda,
                              )
                            : servicio?.precioTexto ?? 'Total',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontFeatures: LavaderoTypography.tabular,
                        ),
                      ),
                      if (conDescuento != null)
                        Text(
                          Formato.moneda(
                            conDescuento.precioLista,
                            conDescuento.moneda,
                          ),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      if (conDescuento != null) ...[
                        const Icon(
                          Icons.local_offer_rounded,
                          size: LavaderoSizes.iconSm,
                          color: LavaderoColors.success,
                        ),
                        const SizedBox(width: LavaderoSpacing.xs),
                      ],
                      Flexible(
                        child: Text(
                          detalle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: conDescuento != null
                                ? LavaderoColors.success
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: LavaderoSpacing.md),
            LoadingButton(
              isLoading: isSubmitting,
              icon: Icons.check_rounded,
              onPressed: onConfirmar,
              child: const Text('Confirmar reserva'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmacionReserva extends StatelessWidget {
  const _ConfirmacionReserva({
    required this.reserva,
    required this.servicio,
    required this.sucursal,
    required this.onVerReservas,
    required this.onReservarOtra,
  });

  final Reserva reserva;
  final ServiceItem? servicio;
  final Sucursal? sucursal;
  final VoidCallback onVerReservas;
  final VoidCallback onReservarOtra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inicio = reserva.fechaHoraInicio.toLocal();
    final relativo = Formato.diaRelativo(inicio);
    final cuando = relativo == 'Hoy' || relativo == 'Mañana'
        ? relativo.toLowerCase()
        : 'el $relativo';
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: LavaderoSizes.formMaxWidth),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(LavaderoSpacing.lg),
          children: [
            const Center(child: SuccessCheck()),
            const SizedBox(height: LavaderoSpacing.md),
            FadeSlideIn(
              index: 3,
              child: Column(
                children: [
                  Text(
                    '¡Reserva confirmada!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: LavaderoSpacing.sm),
                  Text(
                    'Te esperamos $cuando a las ${Formato.hora(inicio)}.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LavaderoSpacing.lg),
            FadeSlideIn(
              index: 5,
              child: LavaderoCard(
                child: Column(
                  children: [
                    _Detalle(
                      icon: Icons.local_car_wash_rounded,
                      label: 'Servicio',
                      valor: servicio?.nombre ?? '—',
                    ),
                    if (sucursal != null)
                      _Detalle(
                        icon: Icons.storefront_rounded,
                        label: 'Sucursal',
                        valor: sucursal!.nombre,
                      ),
                    if (reserva.vehiculoPlaca != null)
                      _Detalle(
                        icon: Icons.directions_car_rounded,
                        label: 'Vehículo',
                        valor: reserva.vehiculoPlaca!,
                      ),
                    _Detalle(
                      icon: Icons.event_rounded,
                      label: 'Fecha',
                      valor: Formato.fechaCorta(inicio),
                    ),
                    _Detalle(
                      icon: Icons.schedule_rounded,
                      label: 'Hora',
                      valor:
                          '${Formato.hora(inicio)} – '
                          '${Formato.hora(reserva.fechaHoraFin.toLocal())}',
                    ),
                    const Divider(height: LavaderoSpacing.lg),
                    if (reserva.descuento > 0)
                      _Detalle(
                        icon: Icons.local_offer_rounded,
                        label: 'Descuento',
                        valor:
                            '−${Formato.moneda(reserva.descuento, reserva.moneda)}',
                      ),
                    _Detalle(
                      icon: Icons.payments_rounded,
                      label: 'Total',
                      valor: Formato.moneda(reserva.precio, reserva.moneda),
                      destacado: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LavaderoSpacing.lg),
            FadeSlideIn(
              index: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: onVerReservas,
                    icon: const Icon(Icons.event_note_rounded),
                    label: const Text('Ver mis reservas'),
                  ),
                  const SizedBox(height: LavaderoSpacing.sm),
                  TextButton(
                    onPressed: onReservarOtra,
                    child: const Text('Reservar otro lavado'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Detalle extends StatelessWidget {
  const _Detalle({
    required this.icon,
    required this.label,
    required this.valor,
    this.destacado = false,
  });

  final IconData icon;
  final String label;
  final String valor;
  final bool destacado;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.xs),
      child: Row(
        children: [
          Icon(
            icon,
            size: LavaderoSizes.iconMd,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: LavaderoSpacing.smd),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Text(
              valor,
              textAlign: TextAlign.end,
              style:
                  (destacado
                          ? theme.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                            )
                          : theme.textTheme.titleSmall)
                      ?.copyWith(fontFeatures: LavaderoTypography.tabular),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paso opcional: los vehículos del cliente como opciones, "Sin vehículo" y
/// un atajo para agregar uno nuevo sin salir de la reserva.
class _VehiculoOpciones extends StatelessWidget {
  const _VehiculoOpciones({
    required this.vehiculos,
    required this.seleccionadoId,
    required this.onElegir,
    required this.onAgregar,
  });

  final List<Vehiculo> vehiculos;
  final String? seleccionadoId;
  final ValueChanged<String?> onElegir;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LavaderoSpacing.sm,
      runSpacing: LavaderoSpacing.sm,
      children: [
        for (final v in vehiculos)
          ChoiceChip(
            avatar: Icon(v.tipo.icono, size: LavaderoSizes.iconSm),
            showCheckmark: false,
            label: Text(v.placa),
            tooltip: v.descripcion,
            selected: v.id == seleccionadoId,
            onSelected: (_) => onElegir(v.id),
          ),
        if (vehiculos.isNotEmpty)
          ChoiceChip(
            showCheckmark: false,
            label: const Text('Sin vehículo'),
            selected: seleccionadoId == null,
            onSelected: (_) => onElegir(null),
          ),
        ActionChip(
          avatar: const Icon(Icons.add_rounded, size: LavaderoSizes.iconSm),
          label: Text(vehiculos.isEmpty ? 'Agregar mi vehículo' : 'Agregar'),
          onPressed: onAgregar,
        ),
      ],
    );
  }
}

/// Campo de cupón: oculto detrás de "¿Tienes un cupón?" para no distraer a
/// quien no tiene; ya aplicado, muestra el código y cuánto descuenta.
class _CuponPaso extends StatefulWidget {
  const _CuponPaso({
    required this.cupon,
    required this.error,
    required this.isAplicando,
    required this.habilitado,
    required this.descuento,
    required this.onAplicar,
    required this.onQuitar,
  });

  final String? cupon;
  final String? error;
  final bool isAplicando;
  final bool habilitado;
  final Cotizacion? descuento;
  final ValueChanged<String> onAplicar;
  final VoidCallback onQuitar;

  @override
  State<_CuponPaso> createState() => _CuponPasoState();
}

class _CuponPasoState extends State<_CuponPaso> {
  final _controller = TextEditingController();
  bool _abierto = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _aplicar() {
    final codigo = _controller.text.trim();
    if (codigo.isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onAplicar(codigo);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cupon = widget.cupon;
    if (cupon != null) {
      final descuento = widget.descuento;
      return Align(
        alignment: Alignment.centerLeft,
        child: InputChip(
          avatar: const Icon(
            Icons.local_offer_rounded,
            size: LavaderoSizes.iconSm,
            color: LavaderoColors.success,
          ),
          label: Text(
            descuento == null
                ? cupon
                : '$cupon · −${Formato.moneda(descuento.descuento, descuento.moneda)}',
          ),
          onDeleted: () {
            _controller.clear();
            widget.onQuitar();
          },
          deleteButtonTooltipMessage: 'Quitar cupón',
        ),
      );
    }
    if (!_abierto) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() => _abierto = true),
          icon: const Icon(Icons.confirmation_number_outlined),
          label: const Text('¿Tienes un cupón?'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _aplicar(),
                maxLength: 20,
                decoration: InputDecoration(
                  hintText: 'Código del cupón',
                  counterText: '',
                  isDense: true,
                  errorText: widget.error,
                  errorMaxLines: 2,
                  helperText: widget.habilitado
                      ? null
                      : 'Elige servicio y hora para aplicarlo',
                ),
              ),
            ),
            const SizedBox(width: LavaderoSpacing.sm),
            LoadingButton(
              isLoading: widget.isAplicando,
              onPressed: widget.habilitado ? _aplicar : null,
              child: const Text('Aplicar'),
            ),
          ],
        ),
        if (widget.error == null && widget.habilitado)
          Padding(
            padding: const EdgeInsets.only(top: LavaderoSpacing.xs),
            child: Text(
              'Si tu hora ya tiene una promoción, se aplica la que más '
              'descuenta.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
