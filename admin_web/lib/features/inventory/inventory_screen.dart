import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../shared/widgets/admin_page.dart';
import 'application/inventory_controller.dart';

enum _Vista { stock, costos }

/// Inventario de insumos (spec 012): stock por sucursal con alertas de
/// reposición y kardex, y el costo de insumos de cada lavado con su margen.
/// Los consumos se descuentan solos al completar una reserva.
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  _Vista _vista = _Vista.stock;

  void _nuevoInsumo() {
    showDialog<void>(
      context: context,
      builder: (context) => const _NuevoInsumoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryControllerProvider);
    final controller = ref.read(inventoryControllerProvider.notifier);
    final puedeGestionar = ref.watch(puedeGestionarInventarioProvider);

    return AdminPage(
      toolbar: PageToolbar(
        leading: Wrap(
          spacing: LavaderoSpacing.md,
          runSpacing: LavaderoSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_Vista>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: _Vista.stock,
                  icon: Icon(Icons.inventory_2_outlined),
                  label: Text('Stock'),
                ),
                ButtonSegment(
                  value: _Vista.costos,
                  icon: Icon(Icons.calculate_outlined),
                  label: Text('Costo por lavado'),
                ),
              ],
              selected: {_vista},
              onSelectionChanged: (s) => setState(() => _vista = s.first),
            ),
            if (_vista == _Vista.stock && state.sucursales.length > 1)
              _SelectorSucursal(
                sucursales: state.sucursales,
                seleccionada: state.sucursalId,
                onChanged: controller.elegirSucursal,
              ),
          ],
        ),
        actions: [
          if (puedeGestionar && _vista == _Vista.stock)
            FilledButton.icon(
              onPressed: _nuevoInsumo,
              icon: const Icon(Icons.add_rounded, size: LavaderoSizes.iconMd),
              label: const Text('Nuevo insumo'),
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
        InventoryState(isLoading: true, insumos: [], costos: []) =>
          const SkeletonList(itemCount: 5, padding: EdgeInsets.zero),
        InventoryState(errorMessage: _?, insumos: [], costos: []) =>
          const SizedBox.shrink(),
        _ when _vista == _Vista.costos => _VistaCostos(
          costos: state.costos,
          insumos: state.insumos,
          puedeEditar: puedeGestionar,
        ),
        InventoryState(insumos: []) => EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Registra tus insumos',
          message:
              'Shampoo, cera, microfibras: agrégalos con su costo y define '
              'cuánto gasta cada servicio. El stock se descuenta solo al '
              'terminar cada lavado.',
          actionLabel: puedeGestionar ? 'Nuevo insumo' : null,
          onAction: puedeGestionar ? _nuevoInsumo : null,
        ),
        _ => _VistaStock(state: state),
      },
    );
  }
}

class _SelectorSucursal extends StatelessWidget {
  const _SelectorSucursal({
    required this.sucursales,
    required this.seleccionada,
    required this.onChanged,
  });

  final List<Sucursal> sucursales;
  final String? seleccionada;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final actual = sucursales.where((s) => s.id == seleccionada).firstOrNull;
    return PopupMenuButton<String>(
      tooltip: 'Sucursal',
      initialValue: seleccionada,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final s in sucursales)
          PopupMenuItem(value: s.id, child: Text(s.nombre)),
      ],
      child: MetaPill(
        icon: Icons.storefront_outlined,
        label: actual?.nombre ?? 'Sucursal',
      ),
    );
  }
}

/// "1.250 ml", "3 und", "-40 g".
String _cantidad(num valor, UnidadMedida unidad) {
  final entero = valor == valor.roundToDouble();
  final texto = entero
      ? Formato.moneda(valor, 'COP').replaceFirst(r'$', '')
      : valor.toStringAsFixed(valor.abs() < 10 ? 2 : 1).replaceAll('.', ',');
  return '$texto ${unidad.corto}';
}

/// Acepta "1.250", "1250" o "0,5".
num? _parsear(String texto) {
  final limpio = texto.trim();
  if (limpio.isEmpty) return null;
  final normalizado = limpio.contains(',')
      ? limpio.replaceAll('.', '').replaceAll(',', '.')
      : (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(limpio)
            ? limpio.replaceAll('.', '')
            : limpio);
  return num.tryParse(normalizado);
}

class _VistaStock extends ConsumerWidget {
  const _VistaStock({required this.state});

  final InventoryState state;

  static const double _anchoTabla = 820;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final porReponer = state.porReponer;
    final valor = state.insumos.fold<num>(0, (s, i) => s + i.valorEnBodega);
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth >= _anchoTabla;
        return ListView(
          padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
          children: [
            ResponsiveGrid(
              minItemWidth: 220,
              maxColumns: 3,
              children: [
                StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Insumos',
                  value: '${state.insumos.length}',
                ),
                StatCard(
                  icon: Icons.notifications_active_outlined,
                  label: 'Por reponer',
                  value: '$porReponer',
                  color: porReponer > 0 ? LavaderoColors.warning : null,
                ),
                StatCard(
                  icon: Icons.payments_outlined,
                  label: 'Valor en bodega',
                  value: Formato.moneda(valor, 'COP'),
                ),
              ],
            ),
            const SizedBox(height: LavaderoSpacing.lg),
            FadeSlideIn(
              child: LavaderoCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (ancho) const _EncabezadoStock(),
                    for (var i = 0; i < state.insumos.length; i++) ...[
                      if (i > 0 || ancho)
                        const Divider(height: LavaderoSizes.hairline),
                      _InsumoFila(
                        insumo: state.insumos[i],
                        sucursalId: state.sucursalId!,
                        ancho: ancho,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EncabezadoStock extends StatelessWidget {
  const _EncabezadoStock();

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
          Expanded(flex: 4, child: Text('INSUMO', style: estilo)),
          Expanded(
            flex: 3,
            child: Text('EN BODEGA', style: estilo, textAlign: TextAlign.end),
          ),
          Expanded(
            flex: 3,
            child: Text('MÍNIMO', style: estilo, textAlign: TextAlign.end),
          ),
          const SizedBox(width: _InsumoFila.anchoAcciones),
        ],
      ),
    );
  }
}

class _InsumoFila extends ConsumerWidget {
  const _InsumoFila({
    required this.insumo,
    required this.sucursalId,
    required this.ancho,
  });

  final InsumoStock insumo;
  final String sucursalId;
  final bool ancho;

  /// Cuatro [IconButton] de área táctil mínima.
  static const double anchoAcciones = 4 * kMinInteractiveDimension;

  Future<void> _abrirCantidad(
    BuildContext context, {
    required String titulo,
    required String etiqueta,
    required String boton,
    required bool conNota,
    required bool permiteCero,
    num? inicial,
    required Future<void> Function(num cantidad, String? nota) guardar,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => _CantidadDialog(
        titulo: titulo,
        subtitulo: insumo.nombre,
        etiqueta: etiqueta,
        unidad: insumo.unidad,
        boton: boton,
        conNota: conNota,
        permiteCero: permiteCero,
        inicial: inicial,
        guardar: guardar,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final controller = ref.read(inventoryControllerProvider.notifier);
    final colorCantidad = insumo.cantidad < 0
        ? scheme.error
        : insumo.bajoMinimo
        ? LavaderoColors.warning
        : null;
    final secundario = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final identidad = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                insumo.nombre,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (insumo.bajoMinimo) ...[
              const SizedBox(width: LavaderoSpacing.sm),
              const StatusBadge(
                label: 'Reponer',
                color: LavaderoColors.warning,
              ),
            ],
          ],
        ),
        Text(
          '${Formato.moneda(insumo.costoUnitario * _unidadCosto(insumo.unidad), insumo.moneda)}'
          ' por ${_textoUnidadCosto(insumo.unidad)}',
          style: secundario,
        ),
      ],
    );
    final cantidad = Text(
      _cantidad(insumo.cantidad, insumo.unidad),
      textAlign: TextAlign.end,
      style: theme.textTheme.titleSmall?.copyWith(
        color: colorCantidad,
        fontFeatures: LavaderoTypography.tabular,
      ),
    );
    final acciones = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Registrar entrada',
          icon: const Icon(Icons.add_box_outlined),
          onPressed: () => _abrirCantidad(
            context,
            titulo: 'Registrar entrada',
            etiqueta: 'Cantidad que llega',
            boton: 'Registrar',
            conNota: true,
            permiteCero: false,
            guardar: (c, n) => controller.registrarEntrada(insumo.id, c, n),
          ),
        ),
        IconButton(
          tooltip: 'Contar bodega',
          icon: const Icon(Icons.fact_check_outlined),
          onPressed: () => _abrirCantidad(
            context,
            titulo: 'Conteo físico',
            etiqueta: 'Cantidad contada',
            boton: 'Guardar conteo',
            conNota: true,
            permiteCero: true,
            guardar: (c, n) => controller.ajustar(insumo.id, c, n),
          ),
        ),
        IconButton(
          tooltip: 'Mínimo para alertar',
          icon: const Icon(Icons.tune_rounded),
          onPressed: () => _abrirCantidad(
            context,
            titulo: 'Mínimo para alertar',
            etiqueta: 'Avisar cuando queden',
            boton: 'Guardar',
            conNota: false,
            permiteCero: true,
            inicial: insumo.minimo,
            guardar: (c, _) => controller.fijarMinimo(insumo.id, c),
          ),
        ),
        IconButton(
          tooltip: 'Ver movimientos',
          icon: const Icon(Icons.history_rounded),
          onPressed: () => showDialog<void>(
            context: context,
            builder: (context) =>
                _KardexDialog(insumo: insumo, sucursalId: sucursalId),
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.lg,
        vertical: LavaderoSpacing.sm,
      ),
      child: ancho
          ? Row(
              children: [
                Expanded(flex: 4, child: identidad),
                Expanded(flex: 3, child: cantidad),
                Expanded(
                  flex: 3,
                  child: Text(
                    insumo.minimo > 0
                        ? _cantidad(insumo.minimo, insumo.unidad)
                        : '—',
                    textAlign: TextAlign.end,
                    style: secundario,
                  ),
                ),
                SizedBox(
                  width: anchoAcciones,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: acciones,
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: identidad),
                    const SizedBox(width: LavaderoSpacing.sm),
                    cantidad,
                  ],
                ),
                Align(alignment: Alignment.centerRight, child: acciones),
              ],
            ),
    );
  }
}

/// El costo se guarda por 1 ml / 1 g, pero se lee mejor por litro / kilo.
num _unidadCosto(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.ml || UnidadMedida.g => 1000,
  UnidadMedida.unidad => 1,
};

String _textoUnidadCosto(UnidadMedida unidad) => switch (unidad) {
  UnidadMedida.ml => 'litro',
  UnidadMedida.g => 'kilo',
  UnidadMedida.unidad => 'unidad',
};

class _VistaCostos extends StatelessWidget {
  const _VistaCostos({
    required this.costos,
    required this.insumos,
    required this.puedeEditar,
  });

  final List<CostoServicio> costos;
  final List<InsumoStock> insumos;
  final bool puedeEditar;

  @override
  Widget build(BuildContext context) {
    if (costos.isEmpty) {
      return const EmptyState(
        icon: Icons.local_car_wash_outlined,
        title: 'Aún no tienes servicios',
        message: 'Crea tus servicios en el catálogo para calcular su costo.',
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: LavaderoSpacing.xl),
      children: [
        ResponsiveGrid(
          minItemWidth: 300,
          maxColumns: 3,
          children: [
            for (final costo in costos)
              _CostoCard(
                costo: costo,
                onEditar: puedeEditar && insumos.isNotEmpty
                    ? () => showDialog<void>(
                        context: context,
                        builder: (context) =>
                            _RecetaDialog(costo: costo, insumos: insumos),
                      )
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _CostoCard extends StatelessWidget {
  const _CostoCard({required this.costo, required this.onEditar});

  final CostoServicio costo;
  final VoidCallback? onEditar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final secundario = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final porcentaje = costo.margenPorcentaje;
    return LavaderoCard(
      padding: const EdgeInsets.all(LavaderoSpacing.lg - LavaderoSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(costo.nombre, style: theme.textTheme.titleMedium),
              ),
              if (!costo.activo)
                StatusBadge(label: 'Inactivo', color: scheme.outline)
              else if (costo.tieneReceta && porcentaje != null)
                StatusBadge(
                  label: 'Margen $porcentaje %',
                  color: porcentaje >= 70
                      ? LavaderoColors.success
                      : LavaderoColors.warning,
                ),
            ],
          ),
          const SizedBox(height: LavaderoSpacing.sm),
          Text(
            'Precio ${Formato.moneda(costo.precio, costo.moneda)}'
            ' · Insumos ${Formato.moneda(costo.costoInsumos, costo.moneda)}',
            style: secundario,
          ),
          const SizedBox(height: LavaderoSpacing.md),
          if (!costo.tieneReceta)
            Text(
              'Sin receta: define qué insumos gasta para conocer su costo y '
              'descontarlos al completar cada lavado.',
              style: secundario,
            )
          else
            for (final l in costo.lineas)
              Padding(
                padding: const EdgeInsets.only(bottom: LavaderoSpacing.xs),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${l.insumo} · ${_cantidad(l.cantidad, l.unidad)}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      Formato.moneda(l.costo, costo.moneda),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFeatures: LavaderoTypography.tabular,
                      ),
                    ),
                  ],
                ),
              ),
          if (onEditar != null) ...[
            const SizedBox(height: LavaderoSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onEditar,
                icon: const Icon(
                  Icons.edit_outlined,
                  size: LavaderoSizes.iconSm,
                ),
                label: Text(
                  costo.tieneReceta ? 'Editar receta' : 'Definir receta',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CantidadDialog extends StatefulWidget {
  const _CantidadDialog({
    required this.titulo,
    required this.subtitulo,
    required this.etiqueta,
    required this.unidad,
    required this.boton,
    required this.conNota,
    required this.permiteCero,
    required this.inicial,
    required this.guardar,
  });

  final String titulo;
  final String subtitulo;
  final String etiqueta;
  final UnidadMedida unidad;
  final String boton;
  final bool conNota;
  final bool permiteCero;
  final num? inicial;
  final Future<void> Function(num cantidad, String? nota) guardar;

  @override
  State<_CantidadDialog> createState() => _CantidadDialogState();
}

class _CantidadDialogState extends State<_CantidadDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _cantidadController = TextEditingController(
    text: widget.inicial == null || widget.inicial == 0
        ? ''
        : widget.inicial.toString(),
  );
  final _notaController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _cantidadController.dispose();
    _notaController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await widget.guardar(
        _parsear(_cantidadController.text)!,
        widget.conNota ? _notaController.text : null,
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
    return LavaderoFormDialog(
      title: widget.titulo,
      subtitle: widget.subtitulo,
      icon: Icons.inventory_2_rounded,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: widget.boton,
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      fields: [
        TextFormField(
          controller: _cantidadController,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: widget.etiqueta,
            suffixText: widget.unidad.corto,
            prefixIcon: const Icon(Icons.straighten_rounded),
          ),
          validator: (v) {
            final valor = _parsear(v ?? '');
            if (valor == null || valor < 0) return 'Cantidad inválida';
            if (!widget.permiteCero && valor == 0) {
              return 'Debe ser mayor que cero';
            }
            return null;
          },
          onFieldSubmitted: (_) => _guardar(),
        ),
        if (widget.conNota)
          TextFormField(
            controller: _notaController,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Nota (opcional)',
              hintText: 'ej. Factura 1234, conteo del lunes',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
      ],
    );
  }
}

class _NuevoInsumoDialog extends ConsumerStatefulWidget {
  const _NuevoInsumoDialog();

  @override
  ConsumerState<_NuevoInsumoDialog> createState() => _NuevoInsumoDialogState();
}

class _NuevoInsumoDialogState extends ConsumerState<_NuevoInsumoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _presentacionController = TextEditingController();
  final _stockController = TextEditingController();
  final _minimoController = TextEditingController();
  UnidadMedida _unidad = UnidadMedida.ml;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _precioController.dispose();
    _presentacionController.dispose();
    _stockController.dispose();
    _minimoController.dispose();
    super.dispose();
  }

  /// El dueño conoce el precio de la presentación ("galón de 3.785 ml a
  /// $45.000"), no el de 1 ml: se calcula aquí.
  num? get _costoUnitario {
    final precio = _parsear(_precioController.text);
    final presentacion = _parsear(_presentacionController.text);
    if (precio == null || presentacion == null || presentacion <= 0) {
      return null;
    }
    return num.parse((precio / presentacion).toStringAsFixed(4));
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(inventoryControllerProvider.notifier)
          .crearInsumo(
            nombre: _nombreController.text,
            unidad: _unidad,
            costoUnitario: _costoUnitario!,
            stockInicial: _parsear(_stockController.text),
            minimo: _parsear(_minimoController.text),
          );
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _requerido(String? v) {
    final valor = _parsear(v ?? '');
    return valor == null || valor <= 0 ? 'Valor inválido' : null;
  }

  String? _opcional(String? v) {
    if ((v ?? '').trim().isEmpty) return null;
    final valor = _parsear(v!);
    return valor == null || valor < 0 ? 'Valor inválido' : null;
  }

  @override
  Widget build(BuildContext context) {
    final u = _unidad.corto;
    final costo = _costoUnitario;
    return LavaderoFormDialog(
      title: 'Nuevo insumo',
      subtitle: 'El stock inicial y el mínimo son para la sucursal elegida.',
      icon: Icons.inventory_2_rounded,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: 'Crear insumo',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      fields: [
        TextFormField(
          controller: _nombreController,
          autofocus: true,
          maxLength: 60,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            hintText: 'ej. Shampoo neutro',
            prefixIcon: Icon(Icons.label_outline_rounded),
          ),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'El nombre es obligatorio'
              : null,
        ),
        SegmentedButton<UnidadMedida>(
          showSelectedIcon: false,
          segments: [
            for (final unidad in UnidadMedida.values)
              ButtonSegment(value: unidad, label: Text(unidad.label)),
          ],
          selected: {_unidad},
          onSelectionChanged: (s) => setState(() => _unidad = s.first),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _precioController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Precio de compra',
                  prefixText: r'$ ',
                ),
                validator: _requerido,
              ),
            ),
            const SizedBox(width: LavaderoSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _presentacionController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(labelText: 'Trae', suffixText: u),
                validator: _requerido,
              ),
            ),
          ],
        ),
        if (costo != null)
          Text(
            'Cuesta ${Formato.moneda(costo * _unidadCosto(_unidad), 'COP')} '
            'por ${_textoUnidadCosto(_unidad)}.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _stockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Hay ahora (opcional)',
                  suffixText: u,
                ),
                validator: _opcional,
              ),
            ),
            const SizedBox(width: LavaderoSpacing.md),
            Expanded(
              child: TextFormField(
                controller: _minimoController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Avisar bajo (opcional)',
                  suffixText: u,
                ),
                validator: _opcional,
                onFieldSubmitted: (_) => _guardar(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RecetaDialog extends ConsumerStatefulWidget {
  const _RecetaDialog({required this.costo, required this.insumos});

  final CostoServicio costo;
  final List<InsumoStock> insumos;

  @override
  ConsumerState<_RecetaDialog> createState() => _RecetaDialogState();
}

class _RecetaDialogState extends ConsumerState<_RecetaDialog> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _controllers = {
    for (final i in widget.insumos)
      i.id: TextEditingController(
        text:
            widget.costo.lineas
                .where((l) => l.insumoId == i.id)
                .firstOrNull
                ?.cantidad
                .toString() ??
            '',
      ),
  };
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final lineas = <String, num>{
      for (final e in _controllers.entries)
        if ((_parsear(e.value.text) ?? 0) > 0) e.key: _parsear(e.value.text)!,
    };
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(inventoryControllerProvider.notifier)
          .definirReceta(widget.costo.servicioId, lineas);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LavaderoFormDialog(
      title: 'Receta de ${widget.costo.nombre}',
      subtitle:
          'Cuánto gasta un lavado de cada insumo. Deja en blanco lo que no '
          'usa. Se descuenta al completar cada reserva.',
      icon: Icons.science_outlined,
      formKey: _formKey,
      isLoading: _isLoading,
      onSubmit: _guardar,
      submitLabel: 'Guardar receta',
      errorMessage: _errorMessage,
      onDismissError: () => setState(() => _errorMessage = null),
      fields: [
        for (final insumo in widget.insumos)
          TextFormField(
            controller: _controllers[insumo.id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: insumo.nombre,
              suffixText: insumo.unidad.corto,
              isDense: true,
            ),
            validator: (v) {
              if ((v ?? '').trim().isEmpty) return null;
              final valor = _parsear(v!);
              return valor == null || valor < 0 ? 'Cantidad inválida' : null;
            },
          ),
      ],
    );
  }
}

class _KardexDialog extends ConsumerWidget {
  const _KardexDialog({required this.insumo, required this.sucursalId});

  final InsumoStock insumo;
  final String sucursalId;

  static const double _ancho = 560;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clave = (insumo: insumo.id, sucursalId: sucursalId);
    final movimientos = ref.watch(
      movimientosProvider((insumoId: insumo.id, sucursalId: sucursalId)),
    );
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
                  Expanded(
                    child: Text(
                      'Movimientos · ${insumo.nombre}',
                      style: theme.textTheme.titleLarge,
                    ),
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
                child: switch (movimientos) {
                  AsyncData(value: []) => const EmptyState(
                    icon: Icons.history_rounded,
                    title: 'Sin movimientos',
                    message: 'Registra una entrada o un conteo para empezar.',
                  ),
                  AsyncData(:final value) => ListView(
                    shrinkWrap: true,
                    children: [
                      for (final m in value) _MovimientoFila(m, insumo.unidad),
                    ],
                  ),
                  AsyncError(:final error) => ErrorBanner(
                    message: error is ApiException
                        ? error.message
                        : 'No se pudieron cargar los movimientos.',
                    onRetry: () => ref.invalidate(
                      movimientosProvider((
                        insumoId: clave.insumo,
                        sucursalId: clave.sucursalId,
                      )),
                    ),
                  ),
                  _ => const SkeletonList.inline(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovimientoFila extends StatelessWidget {
  const _MovimientoFila(this.movimiento, this.unidad);

  final MovimientoInventario movimiento;
  final UnidadMedida unidad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final m = movimiento;
    final (icono, color) = switch (m.tipo) {
      TipoMovimiento.entrada => (
        Icons.south_west_rounded,
        LavaderoColors.success,
      ),
      TipoMovimiento.consumo => (Icons.local_car_wash_outlined, scheme.primary),
      TipoMovimiento.ajuste => (
        Icons.fact_check_outlined,
        LavaderoColors.warning,
      ),
    };
    final signo = m.cantidad > 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.xs),
      child: Row(
        children: [
          Icon(icono, color: color, size: LavaderoSizes.iconMd),
          const SizedBox(width: LavaderoSpacing.smd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.tipo == TipoMovimiento.consumo
                      ? 'Lavado completado'
                      : m.nota ?? m.tipo.label,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Formato.fechaHora(m.creadoEn.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$signo${_cantidad(m.cantidad, unidad)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontFeatures: LavaderoTypography.tabular,
                ),
              ),
              Text(
                'Queda ${_cantidad(m.saldo, unidad)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
