# 005 — Sistema de diseño, Mis reservas, Gestión de planes

**Estado: Implementado** (2026-08-08). Verificado: backend (`./gradlew
build`, incluye RLS/arquitectura), `mobile_app` verificado visualmente en
emulador Android real (tema, Mis reservas, cancelar) — ver
`docs/desarrollo-local.md` sección 7b para 2 bugs adicionales encontrados y
corregidos en el camino (RLS con `SUPER_ADMIN`, 403 vs 500). `admin_web` sin
verificación visual (limitación del entorno), verificado por
tests+`curl`.

## Contexto

Feedback directo del usuario probando la app real: "no me gustan los
diseños, la experiencia es mala, no veo mis reservas, no puedo agregar más
planes, los diseños son muy simples y cuadrados, los colores no me gustan".

Investigación de causa raíz (antes de escribir código):

1. **Diseño "cuadrado"/simple**: `admin_web` y `mobile_app` duplican el
   mismo `AppTheme._themeFrom()` — `ThemeData(useMaterial3: true,
   colorScheme: ColorScheme.fromSeed(...), inputDecorationTheme:
   InputDecorationTheme(border: OutlineInputBorder()))`. Sin `cardTheme`,
   sin `elevatedButtonTheme`, sin tipografía propia, sin radios aplicados
   (`LavaderoRadii` existe en `design_tokens.dart` pero nunca se usa) —
   son los defaults planos de Material 3.
2. **"No veo mis reservas"**: el backend YA expone
   `GET /api/v1/agenda/reservas/mias` (`ReservaController`) y
   `scheduling_repository.dart` YA tiene `misReservas()`/`cancelar()`
   implementados. El único hueco es de UI: `mobile_app`'s `BookingScreen`
   solo crea una reserva y muestra una única confirmación; no existe
   ninguna pantalla de historial.
3. **"No puedo agregar más planes"**: `SubscriptionPlan` tiene modelo de
   dominio + repositorio + adapter JPA, pero cero casos de uso y cero
   controller REST — no hay manera de crear/listar planes vía API.
   `tenant_admin_screen.dart` (donde viviría esta gestión, visible solo
   para `SUPER_ADMIN`) es un placeholder "coming soon" sin empezar.

Confirmado con el usuario: implementar las tres, en este orden (el sistema
de diseño primero, para no reconstruir las otras dos pantallas dos veces).

## 1. Sistema de diseño compartido (`lavadero_core`)

- `design_tokens.dart`: agregar `LavaderoRadii.full` (999, para
  badges/chips tipo pill) y un `LavaderoTypography` con `TextTheme`
  propio (jerarquía clara: headlines con peso 700 y letter-spacing
  ajustado, títulos 600, cuerpo 400, labels 500).
- Nuevo `lavadero_theme.dart`: `LavaderoTheme.light()/dark()` — un único
  builder de `ThemeData` compartido con component theming real:
  `cardTheme` (rounded `lg`, `surfaceTintColor`, elevación sutil),
  `filledButtonTheme`/`outlinedButtonTheme`/`textButtonTheme` (rounded
  `md`, padding generoso), `inputDecorationTheme` (fill sutil +
  `OutlineInputBorder` rounded `md`, no el borde recto por defecto),
  `appBarTheme` (plano, sin sombra, centrado), `chipTheme` (rounded
  `full`, usado por `StatusBadge`), `dividerTheme`, `snackBarTheme`,
  `navigationBarTheme`/`navigationRailTheme` (indicador rounded).
  Reemplaza la lógica duplicada de `admin_web/app_theme.dart` y
  `mobile_app/app_theme.dart` — ambos quedan como wrappers finos que
  delegan a `LavaderoTheme` (mantiene el nombre `AppTheme` que ya
  consume `app.dart` en cada app, cero cambios en los call-sites).
- Nuevos widgets reutilizables en `lavadero_core/lib/src/widgets/`:
  - `StatusBadge` — pill de color + texto (usado por estado de
    `Reserva` y estado activo/inactivo de `Servicio`).
  - `EmptyState` — icono + título + mensaje + acción opcional, para
    listas vacías ("mis reservas" sin reservas, catálogo vacío, etc.).

## 2. Mis reservas (`mobile_app`)

Sin trabajo de backend (ya existe). Solo UI:

- `features/client/reservations/application/my_reservations_controller.dart`
  (`Notifier`, carga `misReservas()` al construir, acción `cancelar(id)`
  que recarga la lista).
- `features/client/reservations/presentation/my_reservations_screen.dart`
  — lista de `Reserva` con `StatusBadge` por estado, fecha/hora, servicio,
  botón cancelar (solo si el estado lo permite —
  `ReservaEstado.PENDIENTE`/`CONFIRMADA`), `EmptyState` si no hay
  reservas.
- Agregar a `client_shell.dart` como cuarta pestaña ("Mis reservas"),
  junto a catálogo/reservar/vehículos.

## 3. Gestión de planes de suscripción (backend + `admin_web`)

Backend (`modules/tenant-management`, mismo patrón que
`CrearTenantUseCase`):

- `application/command/CrearSubscriptionPlanCommand.java`,
  `ActualizarSubscriptionPlanCommand.java` (records).
- `application/usecase/CrearSubscriptionPlanUseCase.java`,
  `ListarSubscriptionPlanesUseCase.java`,
  `ActualizarSubscriptionPlanUseCase.java` — sin filtrado por tenant
  (dato de plataforma, sin RLS, igual que `Tenant`).
- `interfaces/rest/SubscriptionPlanController.java` bajo
  `/api/v1/plataforma/planes`: `POST`/`GET`/`PUT`, todos
  `@PreAuthorize("hasRole('SUPER_ADMIN')")`.

`admin_web`:

- `lavadero_core`: modelo `subscription_plan.dart` + método en
  `tenant_repository.dart` (ya existe el repo, se le agregan
  `listarPlanes()`/`crearPlan()`/`actualizarPlan()`) — mismo patrón que
  `catalog_repository.dart`.
- Reemplazar el placeholder de `tenant_admin_screen.dart`: lista de
  planes (nombre, precio, límites, features) + formulario de alta/edición,
  reutilizando `ErrorBanner`/`LoadingButton`/`EmptyState` del sistema de
  diseño.

**Nota operativa**: no existe ningún usuario `SUPER_ADMIN` sembrado (ver
memoria `dev_seed_data_2026-07-20.md`) — para probar esta pantalla hay que
elevar el rol del usuario admin de prueba con
`insert into usuario_rol values (..., 'SUPER_ADMIN')` igual que se hizo
con `ADMIN_TENANT`.

## Verificación

- `cd admin_web && flutter analyze && flutter test`
- `cd mobile_app && flutter analyze && flutter test`
- `cd backend && ./gradlew build` (incluye `architecture-tests`)
- Verificación manual: correr ambas apps, confirmar visualmente el nuevo
  tema (cards redondeadas, botones/inputs consistentes), crear una
  reserva y verla en "Mis reservas", cancelarla; crear un plan nuevo
  desde `admin_web` como `SUPER_ADMIN` y verlo listado.
