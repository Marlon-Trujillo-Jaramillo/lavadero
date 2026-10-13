import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../auth/application/auth_controller.dart';
import '../../shared/widgets/profile_menu_button.dart';
import '../shifts/application/agenda_controller.dart';
import 'application/incidents_controller.dart';

/// Ícono y color de cada categoría de incidencia.
extension _CategoriaVisual on IncidenciaCategoria {
  IconData get icono => switch (this) {
    IncidenciaCategoria.danioVehiculo => Icons.car_crash_rounded,
    IncidenciaCategoria.clienteAusente => Icons.person_off_rounded,
    IncidenciaCategoria.faltanteInsumo => Icons.inventory_2_rounded,
    IncidenciaCategoria.otro => Icons.help_outline_rounded,
  };

  Color get color => switch (this) {
    IncidenciaCategoria.danioVehiculo => LavaderoColors.error,
    IncidenciaCategoria.clienteAusente => LavaderoColors.warning,
    IncidenciaCategoria.faltanteInsumo => LavaderoColors.info,
    IncidenciaCategoria.otro => LavaderoColors.inkTertiary,
  };
}

/// Incidencias reportadas por el empleado, con un formulario en hoja
/// inferior para reportar una nueva. Ver docs/specs/006-checklist-incidencias.md.
class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(incidentsControllerProvider);
    final controller = ref.read(incidentsControllerProvider.notifier);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Reportar'),
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
              const PageHeader(
                title: 'Incidencias',
                description: 'Lo que reportaste durante tus turnos.',
                trailing: ProfileMenuButton(),
              ),
              if (state.isLoading)
                const SkeletonList.inline(itemCount: 3)
              else if (state.errorMessage != null)
                ErrorBanner(
                  message: state.errorMessage!,
                  onRetry: controller.cargar,
                )
              else if (state.incidencias.isEmpty) ...[
                const SizedBox(height: LavaderoSpacing.xl),
                EmptyState(
                  icon: Icons.verified_outlined,
                  title: 'Sin incidencias',
                  message:
                      'No has reportado incidencias. Si algo sale mal en un '
                      'lavado, repórtalo aquí.',
                  actionLabel: 'Reportar incidencia',
                  onAction: () => _abrirFormulario(context),
                ),
              ] else
                for (var i = 0; i < state.incidencias.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: LavaderoSpacing.sm),
                    child: FadeSlideIn(
                      index: i,
                      child: _IncidenciaCard(incidencia: state.incidencias[i]),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _abrirFormulario(BuildContext context) async {
    final creada = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _IncidenciaFormSheet(),
    );
    if (creada == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incidencia reportada')));
    }
  }
}

class _IncidenciaCard extends StatelessWidget {
  const _IncidenciaCard({required this.incidencia});

  final Incidencia incidencia;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final categoria = incidencia.categoria;
    return LavaderoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: categoria.icono, color: categoria.color),
          const SizedBox(width: LavaderoSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        categoria.label,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '${Formato.diaRelativo(incidencia.creadoEn.toLocal())} · '
                      '${Formato.hora(incidencia.creadoEn.toLocal())}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFeatures: LavaderoTypography.tabular,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LavaderoSpacing.xs),
                Text(incidencia.descripcion, style: theme.textTheme.bodyMedium),
                if (incidencia.reservaId != null) ...[
                  const SizedBox(height: LavaderoSpacing.sm),
                  Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: LavaderoSizes.iconSm,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: LavaderoSpacing.xs),
                      Text(
                        'Asociada a una reserva',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IncidenciaFormSheet extends ConsumerStatefulWidget {
  const _IncidenciaFormSheet();

  @override
  ConsumerState<_IncidenciaFormSheet> createState() =>
      _IncidenciaFormSheetState();
}

class _IncidenciaFormSheetState extends ConsumerState<_IncidenciaFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _descripcionController = TextEditingController();
  IncidenciaCategoria _categoria = IncidenciaCategoria.otro;
  String? _reservaId;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated || authState.user.sucursalId == null) {
      setState(
        () => _errorMessage = 'Tu usuario no tiene una sucursal asignada.',
      );
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(incidentsControllerProvider.notifier)
          .crear(
            sucursalId: authState.user.sucursalId!,
            reservaId: _reservaId,
            categoria: _categoria,
            descripcion: _descripcionController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reservas = ref.watch(agendaControllerProvider).reservas.toList()
      ..sort((a, b) => a.fechaHoraInicio.compareTo(b.fechaHoraInicio));

    Widget etiqueta(String texto) => Padding(
      padding: const EdgeInsets.only(bottom: LavaderoSpacing.sm),
      child: Text(texto, style: theme.textTheme.titleSmall),
    );

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
                Text('Reportar incidencia', style: theme.textTheme.titleLarge),
                const SizedBox(height: LavaderoSpacing.xxs),
                Text(
                  'El administrador del lavadero la verá de inmediato.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: LavaderoSpacing.lg),
                etiqueta('Categoría'),
                Wrap(
                  spacing: LavaderoSpacing.sm,
                  runSpacing: LavaderoSpacing.sm,
                  children: [
                    for (final categoria in IncidenciaCategoria.values)
                      ChoiceChip(
                        avatar: Icon(
                          categoria.icono,
                          size: LavaderoSizes.iconSm,
                          color: categoria.color,
                        ),
                        showCheckmark: false,
                        label: Text(categoria.label),
                        selected: categoria == _categoria,
                        onSelected: (_) =>
                            setState(() => _categoria = categoria),
                      ),
                  ],
                ),
                if (reservas.isNotEmpty) ...[
                  const SizedBox(height: LavaderoSpacing.lg),
                  etiqueta('Reserva relacionada (opcional)'),
                  Wrap(
                    spacing: LavaderoSpacing.sm,
                    runSpacing: LavaderoSpacing.sm,
                    children: [
                      ChoiceChip(
                        showCheckmark: false,
                        label: const Text('Ninguna'),
                        selected: _reservaId == null,
                        onSelected: (_) => setState(() => _reservaId = null),
                      ),
                      for (final reserva in reservas)
                        ChoiceChip(
                          showCheckmark: false,
                          label: Text(
                            Formato.hora(reserva.fechaHoraInicio.toLocal()),
                          ),
                          selected: _reservaId == reserva.id,
                          onSelected: (_) =>
                              setState(() => _reservaId = reserva.id),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: LavaderoSpacing.lg),
                TextFormField(
                  controller: _descripcionController,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    hintText: 'Cuéntanos qué pasó',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Describe qué pasó'
                      : null,
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
                  icon: Icons.send_rounded,
                  child: const Text('Reportar incidencia'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
