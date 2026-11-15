import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../shared/widgets/profile_menu_button.dart';
import 'application/vehicles_controller.dart';

/// "Mis vehículos": el cliente guarda sus carros una vez y los elige al
/// reservar — ver docs/specs/009-mis-vehiculos.md.
class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vehiclesControllerProvider);
    final controller = ref.read(vehiclesControllerProvider.notifier);

    return Scaffold(
      floatingActionButton: state.vehiculos.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => abrirFormularioVehiculo(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Agregar'),
            ),
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
              LavaderoSpacing.xxxl + LavaderoSpacing.lg,
            ),
            children: [
              PageHeader(
                title: 'Mis vehículos',
                description: state.vehiculos.isEmpty
                    ? 'Guárdalos una vez y elígelos al reservar.'
                    : state.vehiculos.length == 1
                    ? '1 vehículo guardado'
                    : '${state.vehiculos.length} vehículos guardados',
                trailing: const ProfileMenuButton(),
              ),
              if (state.errorMessage != null) ...[
                ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: controller.cargar,
                ),
                const SizedBox(height: LavaderoSpacing.md),
              ],
              if (state.isLoading && state.vehiculos.isEmpty)
                const SkeletonList.inline(itemCount: 2)
              else if (state.vehiculos.isEmpty &&
                  state.errorMessage == null) ...[
                const SizedBox(height: LavaderoSpacing.xl),
                EmptyState(
                  icon: Icons.directions_car_rounded,
                  title: 'Tu garaje está vacío',
                  message:
                      'Agrega tu carro o tu moto y la próxima vez reservas '
                      'sin volver a escribir la placa.',
                  actionLabel: 'Agregar vehículo',
                  onAction: () => abrirFormularioVehiculo(context),
                ),
              ] else
                for (var i = 0; i < state.vehiculos.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LavaderoSpacing.sm),
                    child: FadeSlideIn(
                      index: i,
                      child: _VehiculoCard(
                        vehiculo: state.vehiculos[i],
                        archivando: state.archivandoId == state.vehiculos[i].id,
                        onArchivar: () =>
                            _confirmarArchivo(context, ref, state.vehiculos[i]),
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmarArchivo(
    BuildContext context,
    WidgetRef ref,
    Vehiculo vehiculo,
  ) async {
    final confirmado = await ConfirmDialog.show(
      context,
      title: 'Quitar ${vehiculo.placa}',
      message:
          'Ya no aparecerá al reservar. Tus reservas anteriores con este '
          'vehículo no cambian.',
      confirmLabel: 'Quitar',
      icon: Icons.remove_circle_outline_rounded,
      destructive: true,
    );
    if (!confirmado) return;
    await ref.read(vehiclesControllerProvider.notifier).archivar(vehiculo.id);
  }
}

/// Abre el formulario para agregar un vehículo. Devuelve el vehículo creado
/// (o `null` si se cerró), así la pantalla de reservar puede elegirlo de una.
Future<Vehiculo?> abrirFormularioVehiculo(BuildContext context) async {
  final creado = await showModalBottomSheet<Vehiculo>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => const _VehiculoFormSheet(),
  );
  if (creado != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${creado.placa} agregado a tus vehículos')),
    );
  }
  return creado;
}

class _VehiculoCard extends StatelessWidget {
  const _VehiculoCard({
    required this.vehiculo,
    required this.archivando,
    required this.onArchivar,
  });

  final Vehiculo vehiculo;
  final bool archivando;
  final VoidCallback onArchivar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LavaderoCard(
      child: Row(
        children: [
          IconBadge(icon: vehiculo.tipo.icono),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PlacaChip(placa: vehiculo.placa),
                const SizedBox(height: LavaderoSpacing.xs),
                Text(
                  vehiculo.descripcion,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          archivando
              ? const InlineSpinner()
              : IconButton(
                  tooltip: 'Quitar vehículo',
                  onPressed: onArchivar,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
        ],
      ),
    );
  }
}

/// La placa con aspecto de placa: mayúsculas, espaciado y cifras tabulares.
class PlacaChip extends StatelessWidget {
  const PlacaChip({super.key, required this.placa});

  final String placa;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LavaderoSpacing.sm,
        vertical: LavaderoSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(LavaderoRadii.xs),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        placa,
        style: theme.textTheme.titleMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w800,
          letterSpacing: LavaderoSpacing.xxs,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

extension TipoVehiculoIcono on TipoVehiculo {
  IconData get icono => switch (this) {
    TipoVehiculo.automovil => Icons.directions_car_rounded,
    TipoVehiculo.camioneta => Icons.airport_shuttle_rounded,
    TipoVehiculo.moto => Icons.two_wheeler_rounded,
    TipoVehiculo.otro => Icons.commute_rounded,
  };
}

class _VehiculoFormSheet extends ConsumerStatefulWidget {
  const _VehiculoFormSheet();

  @override
  ConsumerState<_VehiculoFormSheet> createState() => _VehiculoFormSheetState();
}

class _VehiculoFormSheetState extends ConsumerState<_VehiculoFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _placa = TextEditingController();
  final _marca = TextEditingController();
  final _color = TextEditingController();
  TipoVehiculo _tipo = TipoVehiculo.automovil;
  bool _isLoading = false;
  String? _errorMessage;

  /// Mismo criterio que el backend (`Placa`): 5 a 8 letras o números, sin
  /// contar espacios ni guiones.
  static final _formatoPlaca = RegExp(r'^[A-Z0-9]{5,8}$');

  @override
  void dispose() {
    _placa.dispose();
    _marca.dispose();
    _color.dispose();
    super.dispose();
  }

  String? _validarPlaca(String? value) {
    final placa = (value ?? '').replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    if (placa.isEmpty) return 'Ingresa la placa';
    if (!_formatoPlaca.hasMatch(placa)) {
      return 'De 5 a 8 letras o números (ej. ABC123)';
    }
    return null;
  }

  Future<void> _guardar() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final vehiculo = await ref
          .read(vehiclesControllerProvider.notifier)
          .registrar(
            placa: _placa.text,
            tipo: _tipo,
            marca: _marca.text,
            color: _color.text,
          );
      if (mounted) Navigator.of(context).pop(vehiculo);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            LavaderoSpacing.lg,
            0,
            LavaderoSpacing.lg,
            LavaderoSpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Agregar vehículo', style: theme.textTheme.titleLarge),
                const SizedBox(height: LavaderoSpacing.xxs),
                Text(
                  'Solo la placa y el tipo son obligatorios.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LavaderoSpacing.lg),
                TextFormField(
                  controller: _placa,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Placa',
                    hintText: 'ABC123',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  validator: _validarPlaca,
                ),
                const SizedBox(height: LavaderoSpacing.lg),
                Text('Tipo', style: theme.textTheme.titleSmall),
                const SizedBox(height: LavaderoSpacing.sm),
                Wrap(
                  spacing: LavaderoSpacing.sm,
                  runSpacing: LavaderoSpacing.sm,
                  children: [
                    for (final tipo in TipoVehiculo.values)
                      ChoiceChip(
                        avatar: Icon(tipo.icono, size: LavaderoSizes.iconSm),
                        showCheckmark: false,
                        label: Text(tipo.label),
                        selected: tipo == _tipo,
                        onSelected: (_) => setState(() => _tipo = tipo),
                      ),
                  ],
                ),
                const SizedBox(height: LavaderoSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _marca,
                        textCapitalization: TextCapitalization.words,
                        inputFormatters: [LengthLimitingTextInputFormatter(40)],
                        decoration: const InputDecoration(
                          labelText: 'Marca (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(width: LavaderoSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _color,
                        textCapitalization: TextCapitalization.sentences,
                        inputFormatters: [LengthLimitingTextInputFormatter(30)],
                        decoration: const InputDecoration(
                          labelText: 'Color (opcional)',
                        ),
                        onFieldSubmitted: (_) => _guardar(),
                      ),
                    ),
                  ],
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: LavaderoSpacing.md),
                  ErrorBanner(
                    message: _errorMessage!,
                    onDismiss: () => setState(() => _errorMessage = null),
                  ),
                ],
                const SizedBox(height: LavaderoSpacing.lg),
                LoadingButton(
                  onPressed: _guardar,
                  isLoading: _isLoading,
                  icon: Icons.check_rounded,
                  child: const Text('Guardar vehículo'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
