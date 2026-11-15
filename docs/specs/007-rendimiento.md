# Spec 007: Rendimiento — qué se hizo, qué no y por qué

## Estado

Fase 1 implementada (2026-11-15). `./gradlew build` verde (incluye el test nuevo de N+1 y el del
filtro de peticiones lentas); `flutter analyze --fatal-infos` y `flutter test` verdes en
`lavadero_core`, `mobile_app` y `admin_web`.

## Contexto

Se revisó una lista de 30 técnicas de rendimiento, una por una, contra el código real del backend
y de las dos apps. Para cada una se decidió hacerla ahora, dejarla como estaba, posponerla o
descartarla, con la razón. Restricción de esta fase: **cero costo** (nada de servicios pagos).

Leyenda: ✅ hecho ahora · ✔️ ya estaba · ⏸ no por ahora (con el motivo) · ➖ no aplica a esta app.

## Base de datos

| Técnica | Estado | En Lavadero |
|---|---|---|
| **Consultas N+1** | ✅ | Los roles de cada usuario y las características de cada plan son `@ElementCollection`: al listar, Hibernate hacía **una consulta extra por fila**. Medido con `EmpleadosConsultasIntegrationTest` (Testcontainers + estadísticas de Hibernate): listar 8 empleados ejecutaba **9 sentencias SQL**. Con `@BatchSize(size = 50)` son **2**, sin importar cuántos empleados haya. El test queda como regresión. Los casos de uso de listas (agenda, reservas, catálogo) ya hacían una sola consulta |
| **Índices** | ✔️ | Convención del proyecto: toda FK o columna de búsqueda lleva su índice en la misma migración (V13, V15, V19, V21) |
| **Pool de conexiones** | ✔️ | HikariCP de Spring Boot (10 conexiones). Suficiente para la carga esperada |
| **Transacciones de solo lectura** | ✔️ | Todos los casos de uso de consulta usan `@Transactional(readOnly = true)` (verificado) |
| **Sin consultas fuera de la transacción** | ✔️ | `spring.jpa.open-in-view: false`: ninguna vista dispara cargas perezosas ocultas |
| **Pedir solo las columnas necesarias** | ⏸ | Las entidades son pequeñas; proyecciones por endpoint añaden código sin ganancia medible hoy |
| **Caché con Redis** | ⏸ | Redis ya está en `docker-compose`, pero las consultas tardan milisegundos. Una caché multi-tenant mal llaveada podría mostrar datos de un lavadero a otro: no compensa el riesgo todavía. Redis entra cuando haya varias instancias (ver abajo) |
| **Servidor cerca de la base de datos** | ⏸ | Se decide al desplegar en AWS (misma región y VPC para la app y RDS) |

## Red y API

| Técnica | Estado | En Lavadero |
|---|---|---|
| **Compresión gzip** | ✅ | `server.compression`: respuestas JSON de más de 1 KB (listas, reportes). Las pequeñas no se comprimen porque ahí cuesta más de lo que ahorra |
| **Paginación** | ✔️ | "Mis reservas" devuelve las 50 más recientes (máximo 200 con `limite`); la agenda se pide por día y sucursal. Pendiente: un "ver historial completo" con páginas en la app |
| **Peticiones en paralelo** | ✔️ | Las pantallas que necesitan datos independientes usan `Future.wait` |
| **Timeouts** | ✔️ / ➖ | La app corta la conexión a los 15 s (Dio). El backend no llama APIs externas: Wompi funciona con redirección al checkout + webhook firmado |
| **Límite de abuso** | ✔️ | Rate limiting (Bucket4j) en login/registro y límite de tamaño del cuerpo |
| **Streaming de IA** | ➖ | La app no usa IA |

## Interfaz

| Técnica | Estado | En Lavadero |
|---|---|---|
| **Virtualizar listas largas** | ✅ / ⏸ | "Mis reservas" (hasta 50 tarjetas animadas) pasó a `ListView.builder`: solo se construyen las que entran en pantalla. Las demás listas están acotadas por naturaleza (sucursales, servicios, empleados, agenda de un día). Pendientes para la fase 2: incidencias y el directorio de lavaderos del administrador, que crecen con el tiempo |
| **Debounce** | ✔️ | Búsqueda de lavaderos en `mobile_app` y en el directorio de `admin_web` |
| **Interfaz optimista** | ✔️ | El checklist del empleado marca el ítem al instante y lo revierte si el backend falla |
| **Evitar re-renders** | ✔️ | Riverpod (`Notifier`) solo reconstruye los widgets que observan el estado que cambió |
| **Imágenes WebP/AVIF, lazy loading de imágenes** | ➖ | Las apps no muestran imágenes de red |

## Descarga de la app (web)

| Técnica | Estado | En Lavadero |
|---|---|---|
| **Quitar dependencias sin usar** | ✅ | `cupertino_icons` estaba declarado en las dos apps y no se usaba: en web su fuente se descarga al arrancar |
| **Fuentes propias y grosores justos** | ✔️ | Plus Jakarta Sans va dentro de la app (sin Google Fonts en runtime) y los cinco grosores se usan |
| **Scripts de terceros** | ✔️ | No hay analítica ni anuncios; Sentry va dentro del bundle |
| **CDN y caché del navegador** | ⏸ | Se configuran al publicar `admin_web` (CloudFront + cabeceras de caché) en la fase de AWS |
| **Dividir el JS por páginas** | ⏸ | Flutter lo permite con `deferred as`; el grueso del archivo es el propio motor de Flutter |
| **SSR / SSG** | ➖ | Flutter Web dibuja en canvas; no genera HTML por pantalla |

## Servidor y observabilidad

| Técnica | Estado | En Lavadero |
|---|---|---|
| **Rastrear peticiones lentas** | ✅ / ✔️ | Nuevo `PeticionesLentasFilter`: un WARN con método, ruta, estado y duración cuando una petición supera `lavadero.observability.slow-request-ms` (500 ms, configurable con `LAVADERO_SLOW_REQUEST_MS`). Registra la ruta sin query string para no guardar datos personales. Ya existían las métricas por endpoint de Actuator (`http.server.requests`, protegidas) y las trazas de Sentry al 10 % |
| **OpenTelemetry completo** | ⏸ | Requiere un colector y un backend de trazas. Se hará en la fase de AWS (ADOT / X-Ray) |
| **Cola de trabajos** | ⏸ | Hoy no hay tareas lentas en la petición. Las notificaciones irán por eventos con *outbox* + Kafka (fase 3) |
| **Varias instancias** | ⏸ | La API ya es *stateless* (JWT), pero el rate limiting vive en memoria de cada instancia (Bucket4j + Caffeine): con varias instancias hay que moverlo a Redis (`bucket4j-redis`). Es el primer motivo real para usar Redis |

## Cómo verificarlo

```bash
cd backend
./gradlew :modules:identity-access:test --tests '*EmpleadosConsultasIntegrationTest'   # N+1 (necesita Docker)
./gradlew :bootstrap:test --tests '*PeticionesLentasFilterTest'
```

Compresión, con el backend corriendo: `curl -s -H 'Accept-Encoding: gzip' -D - -o /dev/null <endpoint con más de 1 KB>` muestra `Content-Encoding: gzip`.
