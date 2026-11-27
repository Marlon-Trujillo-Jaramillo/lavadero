import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';

/// Resumen de un día dentro de la serie de tendencia del dashboard.
class DiaVenta {
  const DiaVenta({required this.fecha, required this.resumen});

  final DateTime fecha;
  final ResumenVentas resumen;
}

/// Estado del dashboard: resumen de **hoy**, el de **ayer** (para el comparativo)
/// y la **serie de los últimos 7 días** (para la tendencia). Todo sale de
/// `/api/v1/agenda/reportes/resumen`, un día por llamada.
class DashboardState {
  const DashboardState({
    this.resumen,
    this.resumenAyer,
    this.serie = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final ResumenVentas? resumen;
  final ResumenVentas? resumenAyer;
  final List<DiaVenta> serie;
  final bool isLoading;
  final String? errorMessage;

  DashboardState copyWith({
    ResumenVentas? resumen,
    ResumenVentas? resumenAyer,
    List<DiaVenta>? serie,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      resumen: resumen ?? this.resumen,
      resumenAyer: resumenAyer ?? this.resumenAyer,
      serie: serie ?? this.serie,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final dashboardControllerProvider =
    NotifierProvider<DashboardController, DashboardState>(
      DashboardController.new,
    );

class DashboardController extends Notifier<DashboardState> {
  static const _diasTendencia = 7;

  @override
  DashboardState build() {
    Future.microtask(cargar);
    return const DashboardState(isLoading: true);
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = ref.read(schedulingRepositoryProvider);
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);
      // Serie cronológica: hace 6 días → hoy.
      final dias = List.generate(
        _diasTendencia,
        (i) => hoy.subtract(Duration(days: _diasTendencia - 1 - i)),
      );
      final resumenes = await Future.wait(
        dias.map((d) => repo.resumenVentas(desde: d, hasta: d)),
      );
      final serie = [
        for (var i = 0; i < dias.length; i++)
          DiaVenta(fecha: dias[i], resumen: resumenes[i]),
      ];
      state = state.copyWith(
        resumen: serie.last.resumen,
        resumenAyer: serie.length >= 2 ? serie[serie.length - 2].resumen : null,
        serie: serie,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    }
  }
}
