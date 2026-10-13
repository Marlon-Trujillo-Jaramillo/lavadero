import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/agenda/application/agenda_controller.dart';
import '../features/branches/application/branches_controller.dart';
import '../features/catalog_pricing/application/catalog_pricing_controller.dart';
import '../features/dashboard/application/dashboard_controller.dart';
import '../features/employees/application/employees_controller.dart';
import '../features/reports/application/reports_controller.dart';
import '../features/subscription/application/subscription_controller.dart';
import '../features/tenant_admin/application/subscription_plan_controller.dart';
import '../features/tenant_admin/application/tenant_directory_controller.dart';

/// Controllers con datos de UNA sesión (tenant + usuario). Son providers globales sin
/// autoDispose (para no recargar al cambiar de sección), así que sin esto sobreviven al logout y
/// el siguiente admin que entra en el mismo navegador veía por un momento los datos del tenant
/// anterior. Toda feature nueva con estado de sesión se agrega aquí.
final List<ProviderOrFamily> proveedoresDeSesion = [
  agendaControllerProvider,
  branchesControllerProvider,
  catalogPricingControllerProvider,
  dashboardControllerProvider,
  employeesControllerProvider,
  reportsControllerProvider,
  subscriptionControllerProvider,
  subscriptionPlanControllerProvider,
  tenantDirectoryControllerProvider,
];

/// Descarta el estado de todas las features: se llama al montar el shell (inicio de cada sesión),
/// mismo patrón que `ClientShell`/`EmployeeShell` en `mobile_app`.
void reiniciarEstadoDeSesion(ProviderContainer container) {
  for (final provider in proveedoresDeSesion) {
    container.invalidate(provider);
  }
}
