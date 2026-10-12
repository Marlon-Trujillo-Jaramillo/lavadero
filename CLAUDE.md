# Lavadero

SaaS multi-tenant para lavaderos de autos. Monolito modular Spring Boot (`backend/`) + dos apps
Flutter (`mobile_app/` cliente+empleado, `admin_web/` dueño/plataforma) + paquete compartido
(`packages/lavadero_core/`). Un solo desarrollador construye y opera esto — ver
`docs/adr/0001-modular-monolith.md` para el porqué de cada decisión estructural antes de proponer
cambiarla.

## Antes de tocar código

- Backend: lee `docs/adr/0001-modular-monolith.md` y el spec relevante en `docs/specs/*.md`.
- Cualquier migración o `*JpaEntity.java`: la Row-Level-Security multi-tenant es la garantía de
  seguridad más importante del proyecto (hubo un incidente real, ver `rls-guardian`). No se toca
  una tabla `tenant_id` sin pasar por su checklist.

## Convenciones no negociables (resumen — el detalle vive en cada agente)

**Backend** (`backend/modules/*`): Clean Architecture por módulo
(`domain → application → infrastructure → interfaces`, verificado por ArchUnit), un caso de uso
por operación (no `XService` gordo — SRP), agregados sin dependencias de framework, `Money`/value
objects en vez de primitivos sueltos, controllers sin try/catch, toda migración de un FK/columna de
lookup lleva su índice, todo caso de uso de solo lectura es `@Transactional(readOnly = true)`.

**Flutter** (`admin_web/`, `mobile_app/`, `packages/lavadero_core/`): CERO codegen (no Freezed, no
`json_serializable`, no `build_runner` — modelos escritos a mano); Riverpod puro (`Notifier`, sin
`@riverpod` generado, sin Bloc/get_it); patrón repositorio (`try { } on DioException catch (e) {
throw ApiException.fromDioException(e); }`); "shell owns nav" (una screen nueva reemplaza un
placeholder existente, no toca el shell/router).

**Sistema de diseño** (`packages/lavadero_core/lib/src/theme/`): CERO `Color(0x...)` fuera de
`design_tokens.dart`, CERO `TextStyle(fontSize: ...)` a mano (usar `Theme.of(context).textTheme`),
CERO `EdgeInsets`/radios con números mágicos (usar `LavaderoSpacing`/`LavaderoRadii`), CERO
`border: OutlineInputBorder()` explícito en un campo (el tema global ya lo define — ponerlo a mano
lo pisa). Estado vacío de una lista → `EmptyState`; badge de estado → `StatusBadge`; banner de error
→ `ErrorBanner`; botón con loading → `LoadingButton`. Antes de escribir un widget nuevo para uno de
estos casos, comprobar si ya existe en `packages/lavadero_core/lib/src/widgets/`.

## Reviewers especializados — úsalos proactivamente, no solo si el usuario los pide por nombre

Después de tocar el código correspondiente y antes de dar el trabajo por terminado:

- **`architecture-guardian`**: cualquier cambio en `backend/modules/*` (capas, wiring de Gradle,
  forma de caso de uso, límites entre módulos, eficiencia de queries).
- **`flutter-reviewer`**: cualquier `.dart` cambiado (codegen, patrón de estado, DI, navegación,
  atomic design, sistema de diseño).
- **`rls-guardian`**: cualquier migración nueva/cambiada o `*JpaEntity.java` con `tenant_id`.

Para una pasada completa del proyecto (no solo el diff actual) — consistencia del sistema de
diseño, SOLID/clean code, rendimiento — usa el skill `quality-audit`.

## Memoria de sesiones previas

Hay memoria persistente entre sesiones (bugs ya encontrados y arreglados, decisiones de producto,
feedback de flujo de trabajo). Si algo en este archivo parece contradecir lo que ves en el código
actual, el código manda — la memoria y este archivo pueden quedar desactualizados.
