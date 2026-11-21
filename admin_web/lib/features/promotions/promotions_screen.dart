import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import 'application/promotions_controller.dart';

/// Promociones del lavadero (spec 011): cupones con código y precios por
/// horario para llenar las horas valle, con lo que generó cada una.
class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  static void abrirFormulario(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _PromocionFormDialog(),
    );
  }

  Future<void> _desactivar(
    BuildContext context,
    WidgetRef ref,
    Promocion promocion,
  ) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: '¿Desactivar "${promocion.nombre}"?',
      message:
          'Dejará de aplicarse a las reservas nuevas. Las que ya se hicieron '
          'conservan su precio y sus resultados se siguen viendo aquí.',
      confirmLabel: 'Desactivar',
      icon: Icons.block_rounded,
      destructive: true,
    );
    if (!confirmado) return;
    await ref
        .read(promotionsControllerProvider.notifier)
        .desactivar(promocion.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(promotionsControllerProvider);
    final controller = ref.read(promotionsControllerProvider.notifier);
    final puedeGestionar = ref.watch(puedeGestionarPromocionesProvider);
    final vigentes = state.promociones
        .where((p) => _estado(p) == _Estado.activa)
        .length;

    return AdminPage(
      toolbar: PageToolbar(
        leading: state.promociones.isEmpty
            ? null
            : ToolbarSummary(
                value: '$vigentes',
                label: vigentes == 1
                    ? 'promoción vigente'
                    : 'promociones vigentes',
              ),
        actions: [
          if (puedeGestionar)
            FilledButton.icon(
              onPressed: () => abrirFormulario(context),
              icon: const Icon(Icons.add_rounded, size: LavaderoSizes.iconMd),
              label: const Text('Nueva promoción'),
            ),
        ],
      ),
      banner: state.errorMessage != null
          ? ErrorBanner(
              message: state.errorMessage!,
              onRetry: controller.cargar,
              onDismiss: controller.descartarError,
            )
          : null,
      body: switch (state) {
        PromotionsState(isLoading: true, promociones: []) =>
          const CardGridSkeleton(minItemWidth: 300),
        PromotionsState(errorMessage: _?, promociones: []) =>
          const SizedBox.shrink(),
        PromotionsState(promociones: []) => EmptyState(
          icon: Icons.local_offer_outlined,
          title: 'Llena tus horas valle',
          message:
              'Crea un precio especial para los días y horas con menos '
              'movimiento, o un cupón para tus clientes. Verás cuántas '
              'reservas e ingresos trae cada uno.',
          actionLabel: puedeGestionar ? 'Nueva promoción' : null,
          onAction: puedeGestionar ? () => abrirFormulario(context) : null,
        ),
        _ => ListView(
          padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
          children: [
            ResponsiveGrid(
              minItemWidth: 300,
              maxColumns: 3,
              children: [
                for (final promocion in state.promociones)
                  _PromocionCard(
                    promocion: promocion,
                    desactivando: state.desactivandoId == promocion.id,
                    onDesactivar:
                        puedeGestionar &&
                            promocion.activa &&
                            state.desactivandoId == null
                        ? () => _desactivar(context, ref, promocion)
                        : null,
                  ),
              ],
            ),
          ],
        ),
      },
    );
  }
}

enum _Estado { activa, programada, agotada, vencida, inactiva }

_Estado _estado(Promocion p, {DateTime? hoy}) {
  final ahora = hoy ?? DateTime.now();
  if (!p.activa) return _Estado.inactiva;
  if (p.vencida(hoy: ahora)) return _Estado.vencida;
  if (p.usosMaximos != null && p.usos >= p.usosMaximos!) return _Estado.agotada;
  if (DateTime(ahora.year, ahora.month, ahora.day).isBefore(p.vigenteDesde)) {
    return _Estado.programada;
  }
  return _Estado.activa;
}

String _descuentoTexto(Promocion p) =>
    p.tipoDescuento == TipoDescuento.porcentaje
    ? '${p.valorDescuento.round()} %'
    : Formato.moneda(p.valorDescuento, p.moneda ?? 'COP');

class _PromocionCard extends StatelessWidget {
  const _PromocionCard({
    required this.promocion,
    required this.desactivando,
    required this.onDesactivar,
  });

  final Promocion promocion;
  final bool desactivando;
  final VoidCallback? onDesactivar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = promocion;
    final estado = _estado(p);
    final vigente = estado == _Estado.activa || estado == _Estado.programada;
    final badge = switch (estado) {
      _Estado.activa => const StatusBadge(
        label: 'Activa',
        color: LavaderoColors.success,
      ),
      _Estado.programada => const StatusBadge(
        label: 'Programada',
        color: LavaderoColors.info,
      ),
      _Estado.agotada => const StatusBadge(
        label: 'Agotada',
        color: LavaderoColors.warning,
      ),
      _Estado.vencida => StatusBadge(label: 'Vencida', color: scheme.outline),
      _Estado.inactiva => StatusBadge(label: 'Inactiva', color: scheme.outline),
    };
    final moneda = p.moneda ?? 'COP';
    final secundario = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    return LavaderoCard(
      padding: const EdgeInsets.all(LavaderoSpacing.lg - LavaderoSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconBadge(
                icon: p.tipo == TipoPromocion.cupon
                    ? Icons.confirmation_number_outlined
                    : Icons.schedule_rounded,
                color: vigente ? scheme.primary : scheme.outline,
              ),
              const SizedBox(width: LavaderoSpacing.smd),
              Expanded(
                child: Text(
                  _descuentoTexto(p),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFeatures: LavaderoTypography.tabular,
                    color: vigente ? null : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: LavaderoSpacing.md),
          Text(p.nombre, style: theme.textTheme.titleMedium),
          const SizedBox(height: LavaderoSpacing.sm),
          Wrap(
            spacing: LavaderoSpacing.sm,
            runSpacing: LavaderoSpacing.sm,
            children: [
              if (p.codigo != null)
                MetaPill(
                  icon: Icons.confirmation_number_outlined,
                  label: p.codigo!,
                ),
              if (p.franja != null)
                MetaPill(icon: Icons.schedule_rounded, label: p.franja!),
              MetaPill(
                icon: Icons.event_outlined,
                label:
                    '${Formato.fechaCorta(p.vigenteDesde)} – '
                    '${Formato.fechaCorta(p.vigenteHasta)}',
              ),
              if (p.usosMaximos != null)
                MetaPill(
                  icon: Icons.people_outline_rounded,
                  label: '${p.usos} de ${p.usosMaximos} usos',
                ),
            ],
          ),
          const Divider(height: LavaderoSpacing.xl),
          Row(
            children: [
              Expanded(
                child: _Resultado(
                  valor: '${p.reservas}',
                  etiqueta: p.reservas == 1 ? 'reserva' : 'reservas',
                ),
              ),
              Expanded(
                child: _Resultado(
                  valor: Formato.moneda(p.ingresos, moneda),
                  etiqueta: 'cobrado',
                ),
              ),
              Expanded(
                child: _Resultado(
                  valor: Formato.moneda(p.descuentoOtorgado, moneda),
                  etiqueta: 'descontado',
                ),
              ),
            ],
          ),
          if (p.reservas > 0 && p.completadas < p.reservas) ...[
            const SizedBox(height: LavaderoSpacing.xs),
            Text(
              '${p.completadas} completadas; el resto aún no se presta.',
              style: secundario,
            ),
          ],
          if (onDesactivar != null || desactivando) ...[
            const SizedBox(height: LavaderoSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: desactivando
                  ? const InlineSpinner()
                  : TextButton.icon(
                      onPressed: onDesactivar,
                      icon: const Icon(
                        Icons.block_rounded,
                        size: LavaderoSizes.iconSm,
                      ),
                      label: const Text('Desactivar'),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Resultado extends StatelessWidget {
  const _Resultado({required this.valor, required this.etiqueta});

  final String valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          valor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontFeatures: LavaderoTypography.tabular,
          ),
        ),
        Text(
          etiqueta,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PromocionFormDialog extends ConsumerStatefulWidget {
  const _PromocionFormDialog();

  @override
  ConsumerState<_PromocionFormDialog> createState() =>
      _PromocionFormDialogState();
}

class _PromocionFormDialogState extends ConsumerState<_PromocionFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _codigoController = TextEditingController();
  final _usosController = TextEditingController();
  final _valorController = TextEditingController();

  TipoPromocion _tipo = TipoPromocion.horario;
  TipoDescuento _tipoDescuento = TipoDescuento.porcentaje;
  final Set<DiaSemana> _dias = {DiaSemana.martes, DiaSemana.miercoles};
  TimeOfDay _desde = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _hasta = const TimeOfDay(hour: 11, minute: 0);
  late DateTimeRange _vigencia;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final hoy = DateTime.now();
    final inicio = DateTime(hoy.year, hoy.month, hoy.day);
    _vigencia = DateTimeRange(
      start: inicio,
      end: inicio.add(const Duration(days: 30)),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _usosController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  static String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static int _minutos(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Acepta "5000", "5.000" o "5,000" para montos en pesos.
  num? _parsearValor(String texto) {
    final limpio = texto.trim().replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(limpio);
  }

  Future<void> _elegirHora({required bool desde}) async {
    final elegida = await showTimePicker(
      context: context,
      initialTime: desde ? _desde : _hasta,
    );
    if (elegida == null) return;
    setState(() => desde ? _desde = elegida : _hasta = elegida);
  }

  Future<void> _elegirVigencia() async {
    final hoy = DateTime.now();
    final elegido = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year, hoy.month, hoy.day),
      lastDate: DateTime(hoy.year + 2, hoy.month, hoy.day),
      initialDateRange: _vigencia,
    );
    if (elegido != null) setState(() => _vigencia = elegido);
  }

  String? get _errorFranja {
    if (_tipo != TipoPromocion.horario) return null;
    if (_dias.isEmpty) return 'Elige al menos un día';
    if (_minutos(_desde) >= _minutos(_hasta)) {
      return 'La hora de inicio debe ser anterior a la de fin';
    }
    return null;
  }

  Future<void> _guardar() async {
    final formularioValido = _formKey.currentState!.validate();
    if (!formularioValido || _errorFranja != null) {
      setState(() {});
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final usos = _usosController.text.trim();
      await ref
          .read(promotionsControllerProvider.notifier)
          .crear(
            nombre: _nombreController.text,
            tipo: _tipo,
            tipoDescuento: _tipoDescuento,
            valorDescuento: _parsearValor(_valorController.text)!,
            vigenteDesde: _vigencia.start,
            vigenteHasta: _vigencia.end,
            codigo: _codigoController.text,
            usosMaximos: usos.isEmpty ? null : int.parse(usos),
            dias: DiaSemana.values.where(_dias.contains).toList(),
            horaDesde: _hhmm(_desde),
            horaHasta: _hhmm(_hasta),
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final porcentaje = _tipoDescuento == TipoDescuento.porcentaje;
    final errorFranja = _errorFranja;

    return LavaderoFormDialog(
      title: 'Nueva promoción',
      subtitle:
          'Las promociones no se acumulan: en cada reserva se aplica la que '
          'más descuenta.',
      icon: Icons.local_offer_rounded,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: 'Crear promoción',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      fields: [
        SegmentedButton<TipoPromocion>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: TipoPromocion.horario,
              label: Text('Por horario'),
            ),
            ButtonSegment(value: TipoPromocion.cupon, label: Text('Cupón')),
          ],
          selected: {_tipo},
          onSelectionChanged: (s) => setState(() => _tipo = s.first),
        ),
        TextFormField(
          controller: _nombreController,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Nombre',
            hintText: _tipo == TipoPromocion.horario
                ? 'ej. Mañanas de semana'
                : 'ej. Bienvenida',
            prefixIcon: const Icon(Icons.label_outline_rounded),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'El nombre es obligatorio'
              : null,
        ),
        if (_tipo == TipoPromocion.cupon)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codigoController,
                  maxLength: 20,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    hintText: 'ej. BIENVENIDA',
                    prefixIcon: Icon(Icons.confirmation_number_outlined),
                  ),
                  validator: (v) {
                    final codigo = (v ?? '').replaceAll(RegExp(r'\s'), '');
                    return RegExp(r'^[A-Za-z0-9-]{4,20}$').hasMatch(codigo)
                        ? null
                        : 'De 4 a 20 letras, números o guiones';
                  },
                ),
              ),
              const SizedBox(width: LavaderoSpacing.md),
              Expanded(
                child: TextFormField(
                  controller: _usosController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Máximo de usos (opcional)',
                    hintText: 'Sin límite',
                    prefixIcon: Icon(Icons.people_outline_rounded),
                  ),
                  validator: (v) {
                    final texto = v?.trim() ?? '';
                    if (texto.isEmpty) return null;
                    final usos = int.tryParse(texto);
                    return usos == null || usos < 1 ? 'Número inválido' : null;
                  },
                ),
              ),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: LavaderoSpacing.xs,
                runSpacing: LavaderoSpacing.xs,
                children: [
                  for (final dia in DiaSemana.values)
                    FilterChip(
                      label: Text(dia.corto),
                      selected: _dias.contains(dia),
                      onSelected: (s) => setState(
                        () => s ? _dias.add(dia) : _dias.remove(dia),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              Wrap(
                spacing: LavaderoSpacing.sm,
                runSpacing: LavaderoSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _elegirHora(desde: true),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('Desde ${_hhmm(_desde)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _elegirHora(desde: false),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text('Hasta ${_hhmm(_hasta)}'),
                  ),
                ],
              ),
              if (errorFranja != null)
                Padding(
                  padding: const EdgeInsets.only(top: LavaderoSpacing.xs),
                  child: Text(
                    errorFranja,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<TipoDescuento>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: TipoDescuento.porcentaje,
                  label: Text('%'),
                ),
                ButtonSegment(
                  value: TipoDescuento.montoFijo,
                  label: Text(r'$'),
                ),
              ],
              selected: {_tipoDescuento},
              onSelectionChanged: (s) =>
                  setState(() => _tipoDescuento = s.first),
            ),
            const SizedBox(width: LavaderoSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _valorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: porcentaje ? 'Descuento' : 'Descuento (COP)',
                  suffixText: porcentaje ? '%' : null,
                  prefixIcon: const Icon(Icons.sell_outlined),
                ),
                validator: (v) {
                  final valor = _parsearValor(v ?? '');
                  if (valor == null || valor <= 0) return 'Valor inválido';
                  if (porcentaje && valor > 90) return 'Máximo 90 %';
                  return null;
                },
                onFieldSubmitted: (_) => _guardar(),
              ),
            ),
          ],
        ),
        OutlinedButton.icon(
          onPressed: _elegirVigencia,
          icon: const Icon(Icons.date_range_rounded),
          label: Text(
            'Vigente del ${Formato.fechaCorta(_vigencia.start)} al '
            '${Formato.fechaCorta(_vigencia.end)}',
          ),
        ),
      ],
    );
  }
}
