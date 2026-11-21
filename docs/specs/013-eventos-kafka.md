# Spec 013: Eventos entre módulos con outbox y Kafka

## Estado

Implementado (2026-11-21). `./gradlew build` verde:
- `OutboxIntegrationTest` (Postgres).
- `KafkaIntegrationTest` (Postgres y Kafka reales, con Testcontainers).
- `ConsumoPorKafkaIntegrationTest`: de punta a punta, de la reserva completada al stock descontado.
- `LayeredArchitectureTest` (8 reglas).
- El chequeo de RLS de todas las migraciones, que incluye V25.

## Contexto

En la spec 012, `inventory` descontaba insumos escuchando `ReservaCompletadaEvent` en la misma
transacción (`BEFORE_COMMIT`). Funciona, pero acopla:
- Si el inventario falla, el lavado no se puede completar.
- Ningún otro proceso o servicio puede reaccionar al evento.

El paso natural es publicarlo en un broker, sin perder la garantía de que el evento existe si y
solo si la reserva se completó.

## El problema del "doble escritura"

"Guardar la reserva y después publicar en Kafka" puede dejar dos estados inconsistentes:
- la reserva se guarda y Kafka no recibe el mensaje (se cae entre las dos operaciones);
- Kafka recibe el mensaje y la transacción se revierte.

La solución es un **outbox transaccional**: el evento se guarda en una tabla, en la misma
transacción que la reserva, y un proceso aparte lo publica después.

```
CompletarReservaUseCase ──(misma transacción)──► reserva + outbox_evento
                                                        │
                                        RelayOutbox (cada 1 s, FOR UPDATE SKIP LOCKED)
                                                        │
                                   TransporteKafka ─► lavadero.reserva.completada ─► ConsumidorKafka
                                   TransporteLocal ─────────────────────────────────► (mismo proceso)
                                                        │
                                               DespachadorEventos (fija TenantContext)
                                                        │
                                       ManejadorReservaCompletada (inventory, idempotente)
```

## Diseño técnico

| Pieza | Decisión |
|---|---|
| `EventoIntegracion` (`contracts`) | Un evento que cruza módulos: serializable a JSON, con su `tenantId` (quien consume no comparte la petición) y una `clave` de partición |
| `CatalogoEventos` (`contracts`) | Nombre estable de cada evento (`reserva.completada`) y su tópico. En el outbox y en los headers viaja el nombre, no la clase Java: renombrar una clase no rompe los mensajes que ya están en vuelo |
| `messaging` (módulo nuevo) | Infraestructura compartida, como `contracts`. ArchUnit verifica que no conozca ningún módulo de negocio. Los módulos solo implementan `ManejadorEvento<E>` |
| `EscritorOutbox` | Escucha `EventoIntegracion` en `BEFORE_COMMIT` y hace el `INSERT` en `outbox_evento`: el cambio de negocio y su evento se confirman juntos. `CompletarReservaUseCase` no cambió: sigue publicando con `ApplicationEventPublisher` |
| `RelayOutbox` | Cada pasada toma 50 eventos pendientes con `FOR UPDATE SKIP LOCKED`: varias instancias del backend no publican dos veces el mismo evento (el test lo prueba con 3 relays en paralelo). Un envío fallido no frena el lote: anota el error y reprograma con backoff exponencial (2, 4, 8 s … hasta 5 min) |
| Transporte enchufable | `kafka` en producción. `local` (por defecto) entrega en el mismo proceso, con la misma garantía, para correr el backend sin broker. El local usa una transacción nueva por entrega (`REQUIRES_NEW`): un manejador que falla no revierte el lote del relay |
| Kafka productor | Clave = id de la reserva (orden por reserva dentro de su partición). Headers con tipo, tenant e id del evento. `acks=all` e idempotencia. El outbox solo marca "publicado" lo que el broker ya confirmó |
| Kafka consumidor | `DefaultErrorHandler` con backoff exponencial. Agotados los reintentos, el mensaje va a `<tópico>.DLT` con el error en los headers, sin frenar la partición. Un JSON ilegible no se reintenta (no se arregla solo) |
| Entrega "al menos una vez" | Si Kafka confirma pero el relay no alcanza a hacer commit, el evento se reenvía. Un rebalanceo también puede reentregar. Por eso todo manejador es idempotente: el del inventario ya lo era (índice único por reserva e insumo), y el test reenvía el mismo mensaje y comprueba que se descuenta una sola vez |
| Tenant | `DespachadorEventos` fija el `TenantContext` del evento antes de llamar al manejador. El `@Transactional` del caso de uso lo lleva a Postgres (`TenantAwareTransactionAspect`), así que RLS aplica igual que en una petición |
| RLS del outbox | Política con una excepción acotada: sin tenant fijado (el relay es un proceso del sistema) se ven todas las filas; con tenant, solo las de ese tenant. Ningún endpoint consulta la tabla y el payload solo lleva ids. El test lo verifica en las dos direcciones |
| Observabilidad | Métrica `lavadero.outbox.pendientes` en `/actuator/metrics`: si crece, algo no está saliendo. Cada fallo deja `intentos`, `ultimo_error` y `proximo_intento` en la fila |

### Consistencia: de atómica a eventual

El descuento de insumos ya no ocurre en la misma transacción que la completación: llega en
milisegundos (local) o en lo que tarde el consumidor (Kafka). A cambio:
- un error del inventario ya no impide completar un lavado;
- el evento queda disponible para otros consumidores, p. ej. notificaciones, analítica, o un
  servicio de inventario separado con su propio grupo de consumidores.

Lo que no cambia: si la reserva se revierte, el evento nunca existió, y si se confirmó, el evento
llegará.

## Configuración

```yaml
lavadero.mensajeria.transporte: ${LAVADERO_MENSAJERIA_TRANSPORTE:local}   # local | kafka
spring.kafka.bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVERS:localhost:9092}
```

En local, `infra/docker-compose.yml` trae un Kafka 3.8 en modo KRaft. Para probar el transporte
real:

```
docker compose -f infra/docker-compose.yml up -d kafka
LAVADERO_MENSAJERIA_TRANSPORTE=kafka ./gradlew :bootstrap:bootRun
```

## Pruebas

- **`OutboxIntegrationTest` (5):**
  - una transacción revertida no deja evento;
  - el relay entrega con el tenant del evento y no repite;
  - un manejador que falla no frena el lote y queda con backoff;
  - RLS con tenant y sin tenant;
  - 3 relays en paralelo sobre 120 eventos: cada evento se entrega exactamente una vez.
- **`KafkaIntegrationTest` (2, Kafka real):**
  - el mensaje lleva su clave y sus headers, y llega al manejador con el tenant;
  - un mensaje que siempre falla termina en `.DLT` y los demás siguen.
- **`ConsumoPorKafkaIntegrationTest` (2, de punta a punta):**
  - una reserva completada descuenta la receta pasando por outbox → relay → Kafka → inventory;
  - un mensaje reentregado se descuenta una sola vez.

## Fuera de alcance

- Purgar el outbox (borrar lo publicado hace más de N días): un job programado o un `pg_cron`.
- Esquemas versionados (Avro/Schema Registry): hoy el contrato es el record de `contracts`, y los
  cambios son aditivos.
- Más eventos: `ReservaCreada` y `ReservaCancelada` para notificaciones. Agregarlos es una entrada
  en `CatalogoEventos` y un `ManejadorEvento`.
