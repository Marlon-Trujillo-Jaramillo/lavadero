import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../application/reports_controller.dart';

/// Utilidad del periodo (ingresos − gastos) y gestión de gastos operativos.
class UtilidadView extends ConsumerWidget {
  const UtilidadView({super.key, required this.finanzas, required this.gastos});

  final ResumenFinanciero finanzas;
  final List<Gasto> gastos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final utilidadColor = finanzas.utilidad >= 0
        ? LavaderoColors.success
        : LavaderoColors.error;
    final moneda = finanzas.moneda;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Utilidad del periodo', style: textTheme.titleMedium),
        const SizedBox(height: LavaderoSpacing.smd),
        Wrap(
          spacing: LavaderoSpacing.md,
          runSpacing: LavaderoSpacing.md,
          children: [
            SizedBox(
              width: 220,
              child: StatCard(
                icon: Icons.payments_outlined,
                label: 'Ingresos',
                value: Formato.moneda(finanzas.ingresos, moneda),
              ),
            ),
            SizedBox(
              width: 220,
              child: StatCard(
                icon: Icons.receipt_long_outlined,
                label: 'Gastos',
                value: Formato.moneda(finanzas.gastos, moneda),
              ),
            ),
            SizedBox(
              width: 220,
              child: StatCard(
                icon: finanzas.utilidad >= 0
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                label: 'Utilidad',
                value: Formato.moneda(finanzas.utilidad, moneda),
                color: utilidadColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: LavaderoSpacing.lg),
        Row(
          children: [
            Expanded(
              child: Text('Gastos del periodo', style: textTheme.titleMedium),
            ),
            TextButton.icon(
              onPressed: () => _abrirDialogo(context, ref),
              icon: const Icon(Icons.add_rounded, size: LavaderoSizes.iconSm),
              label: const Text('Agregar gasto'),
            ),
          ],
        ),
        const SizedBox(height: LavaderoSpacing.sm),
        if (gastos.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Sin gastos en este periodo',
            message:
                'Registra arriendo, nómina, insumos y más para ver tu utilidad real.',
          )
        else
          ...gastos.map((g) => _GastoTile(gasto: g)),
      ],
    );
  }

  Future<void> _abrirDialogo(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AgregarGastoDialog(
        controller: ref.read(reportsControllerProvider.notifier),
      ),
    );
  }
}

class _GastoTile extends StatelessWidget {
  const _GastoTile({required this.gasto});

  final Gasto gasto;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LavaderoSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(gasto.descripcion, style: textTheme.bodyMedium),
                Text(
                  '${gasto.categoria.label} · ${Formato.fechaCorta(gasto.fecha)}',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formato.moneda(gasto.monto, gasto.moneda),
            style: textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _AgregarGastoDialog extends StatefulWidget {
  const _AgregarGastoDialog({required this.controller});

  final ReportsController controller;

  @override
  State<_AgregarGastoDialog> createState() => _AgregarGastoDialogState();
}

class _AgregarGastoDialogState extends State<_AgregarGastoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descripcion = TextEditingController();
  final _monto = TextEditingController();
  CategoriaGasto _categoria = CategoriaGasto.arriendo;
  DateTime _fecha = DateTime.now();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _descripcion.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final error = await widget.controller.registrarGasto(
      fecha: _fecha,
      categoria: _categoria,
      descripcion: _descripcion.text.trim(),
      monto: double.parse(_monto.text.trim()),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _isLoading = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar gasto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: LavaderoSpacing.md),
            ],
            DropdownButtonFormField<CategoriaGasto>(
              initialValue: _categoria,
              decoration: const InputDecoration(labelText: 'Categoría'),
              items: [
                for (final c in CategoriaGasto.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (c) => setState(() => _categoria = c ?? _categoria),
            ),
            const SizedBox(height: LavaderoSpacing.md),
            TextFormField(
              controller: _descripcion,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLength: 120,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Describe el gasto' : null,
            ),
            TextFormField(
              controller: _monto,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: r'$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              validator: (v) {
                final monto = double.tryParse((v ?? '').trim());
                return (monto == null || monto <= 0)
                    ? 'Ingresa un monto mayor que cero'
                    : null;
              },
            ),
            const SizedBox(height: LavaderoSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _elegirFecha,
                icon: const Icon(
                  Icons.event_outlined,
                  size: LavaderoSizes.iconSm,
                ),
                label: Text('Fecha: ${Formato.fechaCorta(_fecha)}'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        LoadingButton(
          isLoading: _isLoading,
          onPressed: _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _elegirFecha() async {
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (elegida != null) setState(() => _fecha = elegida);
  }
}
