import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../app/di/providers.dart';
import '../shared/widgets/admin_page.dart';
import 'application/crm_controller.dart';
import 'application/mensaje_sugerido.dart';

/// CRM de clientes (spec 010): quién viene, cuánto gasta, quién dejó de
/// venir. La segmentación la calcula el backend con el ritmo de cada
/// cliente; aquí se filtra por ella, se busca y se abre la ficha.
class CrmScreen extends ConsumerStatefulWidget {
  const CrmScreen({super.key});

  @override
  ConsumerState<CrmScreen> createState() => _CrmScreenState();
}

class _CrmScreenState extends ConsumerState<CrmScreen> {
  static const _esperaBusqueda = Duration(milliseconds: 350);

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _alEscribir(String texto) {
    _debounce?.cancel();
    _debounce = Timer(
      _esperaBusqueda,
      () => ref.read(crmControllerProvider.notifier).buscar(texto),
    );
  }

  void _abrirFicha(ClienteCrm cliente) {
    showDialog<void>(
      context: context,
      builder: (context) => _FichaClienteDialog(cliente: cliente),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(crmControllerProvider);
    final controller = ref.read(crmControllerProvider.notifier);
    final sinClientes =
        !state.isLoading &&
        state.errorMessage == null &&
        !state.hayFiltros &&
        state.clientes.isEmpty;

    return AdminPage(
      toolbar: sinClientes
          ? null
          : PageToolbar(
              leading: _Buscador(onChanged: _alEscribir),
              actions: [
                _SelectorOrden(
                  orden: state.orden,
                  onChanged: controller.ordenar,
                ),
              ],
            ),
      banner: state.errorMessage != null
          ? ErrorBanner(
              message: state.errorMessage!,
              onRetry: controller.cargar,
            )
          : null,
      body: switch (state) {
        _ when sinClientes => const EmptyState(
          icon: Icons.groups_outlined,
          title: 'Aún no tienes clientes',
          message:
              'Cuando tus clientes creen su cuenta y reserven desde la app, '
              'aquí verás sus visitas, su gasto y quién dejó de venir.',
        ),
        CrmState(isLoading: true, clientes: []) => const SkeletonList(
          itemCount: 6,
          padding: EdgeInsets.zero,
        ),
        // Si la carga falló, el banner ya lo explica.
        CrmState(errorMessage: _?, clientes: []) => const SizedBox.shrink(),
        _ => _ListaClientes(
          state: state,
          onSegmento: controller.elegirSegmento,
          onCargarMas: controller.cargarMas,
          onAbrir: _abrirFicha,
        ),
      },
    );
  }
}

class _Buscador extends StatelessWidget {
  const _Buscador({required this.onChanged});

  final ValueChanged<String> onChanged;

  static const double _ancho = 320;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _ancho,
      child: TextField(
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Buscar por nombre o email',
          prefixIcon: Icon(Icons.search_rounded),
          isDense: true,
        ),
      ),
    );
  }
}

class _SelectorOrden extends StatelessWidget {
  const _SelectorOrden({required this.orden, required this.onChanged});

  final OrdenClientes orden;
  final ValueChanged<OrdenClientes> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<OrdenClientes>(
      tooltip: 'Ordenar',
      initialValue: orden,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final opcion in OrdenClientes.values)
          PopupMenuItem(value: opcion, child: Text(opcion.label)),
      ],
      child: MetaPill(icon: Icons.sort_rounded, label: orden.label),
    );
  }
}

Color _colorSegmento(SegmentoCliente segmento, ColorScheme scheme) =>
    switch (segmento) {
      SegmentoCliente.nuevo => LavaderoColors.info,
      SegmentoCliente.frecuente => LavaderoColors.success,
      SegmentoCliente.enRiesgo => LavaderoColors.warning,
      SegmentoCliente.ocasional => scheme.primary,
      SegmentoCliente.sinVisitas => scheme.outline,
    };

class _ListaClientes extends StatelessWidget {
  const _ListaClientes({
    required this.state,
    required this.onSegmento,
    required this.onCargarMas,
    required this.onAbrir,
  });

  final CrmState state;
  final ValueChanged<SegmentoCliente?> onSegmento;
  final VoidCallback onCargarMas;
  final ValueChanged<ClienteCrm> onAbrir;

  static const double _anchoTabla = 820;

  @override
  Widget build(BuildContext context) {
    final enRiesgo = state.porSegmento[SegmentoCliente.enRiesgo] ?? 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth >= _anchoTabla;
        return ListView(
          padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
          children: [
            _FiltrosSegmento(
              seleccionado: state.segmento,
              porSegmento: state.porSegmento,
              total: state.totalSinSegmento,
              onChanged: onSegmento,
            ),
            const SizedBox(height: LavaderoSpacing.md),
            if (enRiesgo > 0 && state.segmento != SegmentoCliente.enRiesgo) ...[
              _AvisoEnRiesgo(
                cantidad: enRiesgo,
                onVer: () => onSegmento(SegmentoCliente.enRiesgo),
              ),
              const SizedBox(height: LavaderoSpacing.md),
            ],
            if (state.clientes.isEmpty)
              EmptyState(
                icon: Icons.person_search_outlined,
                title: 'Sin resultados',
                message: state.busqueda.trim().isEmpty
                    ? 'No hay clientes en este segmento.'
                    : 'Ningún cliente coincide con "${state.busqueda.trim()}".',
              )
            else
              FadeSlideIn(
                child: LavaderoCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      if (ancho) const _EncabezadoTabla(),
                      for (var i = 0; i < state.clientes.length; i++) ...[
                        if (i > 0 || ancho)
                          const Divider(height: LavaderoSizes.hairline),
                        _ClienteFila(
                          cliente: state.clientes[i],
                          ancho: ancho,
                          onTap: () => onAbrir(state.clientes[i]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            if (state.hayMas) ...[
              const SizedBox(height: LavaderoSpacing.md),
              Center(
                child: LoadingButton(
                  onPressed: onCargarMas,
                  isLoading: state.isLoadingMore,
                  icon: Icons.expand_more_rounded,
                  child: Text(
                    'Cargar más (${state.clientes.length} de ${state.total})',
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FiltrosSegmento extends StatelessWidget {
  const _FiltrosSegmento({
    required this.seleccionado,
    required this.porSegmento,
    required this.total,
    required this.onChanged,
  });

  final SegmentoCliente? seleccionado;
  final Map<SegmentoCliente, int> porSegmento;
  final int total;
  final ValueChanged<SegmentoCliente?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: LavaderoSpacing.sm,
      runSpacing: LavaderoSpacing.sm,
      children: [
        ChoiceChip(
          label: Text('Todos · $total'),
          selected: seleccionado == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final segmento in SegmentoCliente.values)
          Tooltip(
            message: segmento.descripcion,
            child: ChoiceChip(
              label: Text('${segmento.label} · ${porSegmento[segmento] ?? 0}'),
              selected: seleccionado == segmento,
              onSelected: (_) =>
                  onChanged(seleccionado == segmento ? null : segmento),
            ),
          ),
      ],
    );
  }
}

class _AvisoEnRiesgo extends StatelessWidget {
  const _AvisoEnRiesgo({required this.cantidad, required this.onVer});

  final int cantidad;
  final VoidCallback onVer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final texto = cantidad == 1
        ? '1 cliente ya debería haber vuelto según su ritmo.'
        : '$cantidad clientes ya deberían haber vuelto según su ritmo.';
    return LavaderoCard(
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.notifications_active_outlined,
            color: LavaderoColors.warning,
          ),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Clientes en riesgo', style: theme.textTheme.titleSmall),
                Text(
                  '$texto Escríbeles antes de perderlos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          TextButton(onPressed: onVer, child: const Text('Ver')),
        ],
      ),
    );
  }
}

class _EncabezadoTabla extends StatelessWidget {
  const _EncabezadoTabla();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estilo = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Container(
      color: theme.colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.lg,
        vertical: LavaderoSpacing.smd,
      ),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('CLIENTE', style: estilo)),
          Expanded(flex: 3, child: Text('SEGMENTO', style: estilo)),
          Expanded(
            flex: 2,
            child: Text('VISITAS', style: estilo, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 3,
            child: Text('GASTO', style: estilo, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'ÚLTIMA VISITA',
              style: estilo,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

String _ultimaVisita(ClienteCrm cliente) {
  final dias = cliente.diasSinVenir();
  return switch (dias) {
    null => 'Nunca',
    0 => 'Hoy',
    1 => 'Ayer',
    _ => 'Hace $dias días',
  };
}

class _ClienteFila extends StatelessWidget {
  const _ClienteFila({
    required this.cliente,
    required this.ancho,
    required this.onTap,
  });

  final ClienteCrm cliente;
  final bool ancho;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final segmento = StatusBadge(
      label: cliente.segmento.label,
      color: _colorSegmento(cliente.segmento, scheme),
    );
    final secundario = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final gasto = Formato.moneda(cliente.gastoTotal, cliente.moneda);
    final identidad = Row(
      children: [
        AvatarInitials(name: cliente.nombre),
        const SizedBox(width: LavaderoSpacing.smd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cliente.nombre,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
              Text(
                cliente.email,
                overflow: TextOverflow.ellipsis,
                style: secundario,
              ),
            ],
          ),
        ),
      ],
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LavaderoSpacing.lg,
          vertical: LavaderoSpacing.smd,
        ),
        child: ancho
            ? Row(
                children: [
                  Expanded(flex: 5, child: identidad),
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: segmento,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${cliente.visitas}',
                      textAlign: TextAlign.end,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      gasto,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      _ultimaVisita(cliente),
                      textAlign: TextAlign.end,
                      style: secundario,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: identidad),
                  const SizedBox(width: LavaderoSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      segmento,
                      const SizedBox(height: LavaderoSpacing.xs),
                      Text(
                        '$gasto · ${_ultimaVisita(cliente)}',
                        style: secundario,
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class _FichaClienteDialog extends ConsumerWidget {
  const _FichaClienteDialog({required this.cliente});

  final ClienteCrm cliente;

  static const double _ancho = 640;

  Future<void> _escribir(BuildContext context, WidgetRef ref) async {
    final abierto = await ref.read(abrirUrlExternaProvider)(
      correoSugerido(cliente),
    );
    if (!abierto && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir tu correo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ficha = ref.watch(fichaClienteProvider(cliente.id));

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _ancho),
        child: Padding(
          padding: const EdgeInsets.all(LavaderoSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  AvatarInitials(
                    name: cliente.nombre,
                    size: LavaderoSizes.avatarLg,
                  ),
                  const SizedBox(width: LavaderoSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cliente.nombre,
                          style: theme.textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          cliente.email,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: cliente.segmento.label,
                    color: _colorSegmento(cliente.segmento, theme.colorScheme),
                  ),
                  IconButton(
                    tooltip: 'Cerrar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: LavaderoSpacing.md),
              Flexible(
                child: switch (ficha) {
                  AsyncData(:final value) => _ContenidoFicha(ficha: value),
                  AsyncError(:final error) => ErrorBanner(
                    message: error is ApiException
                        ? error.message
                        : 'No se pudo cargar la ficha.',
                    onRetry: () =>
                        ref.invalidate(fichaClienteProvider(cliente.id)),
                  ),
                  _ => const SkeletonList.inline(),
                },
              ),
              const SizedBox(height: LavaderoSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _escribir(context, ref),
                  icon: const Icon(
                    Icons.mail_outline_rounded,
                    size: LavaderoSizes.iconMd,
                  ),
                  label: const Text('Escribirle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContenidoFicha extends StatelessWidget {
  const _ContenidoFicha({required this.ficha});

  final FichaCliente ficha;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cliente = ficha.cliente;
    final proxima = cliente.proximaReserva;

    return ListView(
      shrinkWrap: true,
      children: [
        Wrap(
          spacing: LavaderoSpacing.sm,
          runSpacing: LavaderoSpacing.sm,
          children: [
            MetaPill(
              icon: Icons.local_car_wash_outlined,
              label: cliente.visitas == 1
                  ? '1 visita'
                  : '${cliente.visitas} visitas',
            ),
            MetaPill(
              icon: Icons.payments_outlined,
              label: Formato.moneda(cliente.gastoTotal, cliente.moneda),
            ),
            MetaPill(
              icon: Icons.history_rounded,
              label: 'Última: ${_ultimaVisita(cliente).toLowerCase()}',
            ),
            if (proxima != null)
              MetaPill(
                icon: Icons.event_available_outlined,
                label: 'Próxima: ${Formato.fechaCorta(proxima.toLocal())}',
                color: LavaderoColors.success,
              ),
            if (ficha.servicioFavorito != null)
              MetaPill(
                icon: Icons.favorite_outline_rounded,
                label: ficha.servicioFavorito!,
              ),
          ],
        ),
        const SizedBox(height: LavaderoSpacing.lg),
        Text('Vehículos', style: theme.textTheme.titleSmall),
        const SizedBox(height: LavaderoSpacing.sm),
        if (ficha.vehiculos.isEmpty)
          Text(
            'No ha registrado vehículos.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Wrap(
            spacing: LavaderoSpacing.sm,
            runSpacing: LavaderoSpacing.sm,
            children: [
              for (final v in ficha.vehiculos)
                MetaPill(
                  icon: Icons.directions_car_outlined,
                  label: '${v.placa} · ${v.descripcion}',
                ),
            ],
          ),
        const SizedBox(height: LavaderoSpacing.lg),
        Text('Últimas reservas', style: theme.textTheme.titleSmall),
        const SizedBox(height: LavaderoSpacing.sm),
        if (ficha.historial.isEmpty)
          Text(
            'Todavía no tiene reservas.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          for (final visita in ficha.historial) _VisitaFila(visita: visita),
      ],
    );
  }
}

class _VisitaFila extends StatelessWidget {
  const _VisitaFila({required this.visita});

  final VisitaCliente visita;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detalle = [
      Formato.fechaHora(visita.fecha.toLocal()),
      visita.sucursal,
      if (visita.placa != null) visita.placa!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(visita.servicio, style: theme.textTheme.bodyMedium),
                Text(
                  detalle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          Text(
            Formato.moneda(visita.precio, visita.moneda),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(width: LavaderoSpacing.sm),
          ReservaEstadoBadge(estado: visita.estado),
        ],
      ),
    );
  }
}
