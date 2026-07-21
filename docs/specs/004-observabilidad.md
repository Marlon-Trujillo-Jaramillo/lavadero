# Spec 004: Observabilidad y monitoreo de errores

## Estado

Implementado (con `SENTRY_DSN` vacío — sin cuenta de Sentry creada
todavía). Backend: `sentry-spring-boot-starter-jakarta` en `bootstrap`,
config en `application.yml`. Flutter: `sentry` (base) en `lavadero_core`
para reportar `ApiException` (breadcrumb para rechazos de negocio 4xx,
evento capturado para 5xx/errores de red); `sentry_flutter` en `admin_web`
y `mobile_app`, inicializado en `bootstrap()`/cada `main_*.dart`. Todo
verde con DSN vacío (`./gradlew build`, `flutter analyze`/`test` en las
tres apps/paquetes). Pendiente del lado del usuario: crear las 3 cuentas
de proyecto en sentry.io (backend, admin_web, mobile_app) y configurar
`SENTRY_DSN` en el entorno de despliegue — sin cambios de código
adicionales.

## Contexto

Un solo desarrollador opera este SaaS en producción (ver ADR 0001): sin
monitoreo, un error en producción solo se entera cuando un cliente se
queja. El pedido es tener una red de seguridad ("por si acaso") sin
montar infraestructura de observabilidad pesada (Prometheus/Grafana/ELK),
consistente con la filosofía de mínima complejidad operativa del proyecto.

## Decisión

**Sentry** (sentry.io, tier gratuito) para monitoreo de errores en las tres
superficies (backend + 2 apps Flutter): un solo panel agrega excepciones no
manejadas de Java y crashes/errores de Flutter, con alertas por email.
Se descarta una stack de observabilidad self-hosted (Prometheus/Grafana)
por ahora: da más (métricas, dashboards, tracing detallado) pero exige
mantener infraestructura adicional que un solo desarrollador debe operar —
desproporcionado para el volumen de tráfico esperado en esta fase (ver
ADR 0001). Si el negocio crece lo suficiente, se reevalúa.

Alcance de esta spec: **captura y alerta de errores**, no un dashboard de
métricas de negocio (eso ya lo cubre `docs/specs/003-dashboard-reportes.md`)
ni tracing de performance detallado (Sentry lo soporta, pero se deja
apagado/con sampling mínimo para no generar costo/ruido innecesario en esta
fase).

## Diseño técnico

### Backend

- `sentry-spring-boot-starter-jakarta:8.16.0` (Jakarta EE — Spring Boot 3.x
  usa ese namespace, no `javax`) en `bootstrap/build.gradle.kts` (el DSN es
  específico del proceso ejecutable, no de cada módulo librería).
- Configuración vía variable de entorno `SENTRY_DSN` (nunca hardcodeada,
  mismo patrón que `LAVADERO_SECURITY_JWT_SECRET`): si está vacía/ausente,
  el SDK de Sentry no envía nada (comportamiento por defecto de la
  librería) — el build/arranque nunca falla por falta de DSN.
- `sentry.environment` = el perfil activo (`dev`/`prod`, vía
  `spring.profiles.active`); `sentry.traces-sample-rate` bajo (0.1) para
  tener trazas de performance mínimas sin costo alto.
- `GlobalExceptionHandler` (bootstrap) ya captura toda excepción no
  manejada — el `SentryExceptionResolver` que trae el starter se engancha
  automáticamente ahí sin tocar ese código.

### Flutter (`admin_web`, `mobile_app`)

- `sentry_flutter: ^9.24.0` en ambos `pubspec.yaml`.
- DSN vía `--dart-define=SENTRY_DSN=...` (mismo mecanismo que
  `API_BASE_URL` en `admin_web/lib/app/di/environment.dart`; en
  `mobile_app`, se añade al `AppEnvironment` de cada `main_*.dart`). DSN
  vacío = SDK inicializado en modo no-op (no rompe builds locales sin DSN
  configurado).
- `SentryFlutter.init(...)` envuelve `runApp` en `bootstrap()`
  (`admin_web`) y en cada `main_*.dart` (`mobile_app`) — captura errores no
  manejados de Flutter/Dart automáticamente.
- `ApiException` (ya centraliza todos los errores de red/API) se reporta a
  Sentry como breadcrumb/evento manual en `AuthInterceptor`/donde se
  captura, para tener contexto de qué llamada falló — sin loguear tokens ni
  contraseñas (los interceptors ya no exponen esos valores en el mensaje).

## Verificación

- Con `SENTRY_DSN` vacío (caso por defecto en este entorno, sin cuenta de
  Sentry creada todavía): `./gradlew build`, `flutter analyze`/`flutter
  test` en ambas apps — todo debe seguir verde, cero cambio de
  comportamiento observable.
- Cuando el usuario cree su cuenta en sentry.io y provea los DSN reales
  (uno por proyecto: backend, admin_web, mobile_app), configurarlos como
  variables de entorno/dart-define en el entorno de despliegue — sin
  cambios de código adicionales.
