# Spec 010: CRM de clientes

## Estado

Implementado (2026-11-20). `./gradlew build` verde (incluye `ClienteCrmIntegrationTest` contra
Postgres real, `ClienteCrmUseCasesTest` y `ClienteCrmControllerTest`). `flutter analyze
--fatal-infos` y `flutter test` verdes en `lavadero_core` y `admin_web`.

## Contexto

"CRM" era un `ComingSoonPlaceholder` en la web del dueño. Prometía tres cosas:
- una ficha de cada cliente;
- detectar a los frecuentes y a los que están en riesgo;
- mensajes de recordatorio.

El lavadero ya tenía los datos para las tres (reservas, precios congelados y, desde la spec 009,
vehículos). Faltaba leerlos por cliente.

## Requisitos

- Lista de clientes del lavadero con visitas completadas, gasto total, última visita, próxima
  reserva, vehículos y segmento.
- Filtrar por segmento, ver cuántos hay en cada uno, buscar por nombre o email y ordenar.
- La lista se pagina en el servidor, porque un lavadero con años de uso tiene miles de clientes.
- Ficha del cliente con:
  - resumen;
  - servicio favorito;
  - vehículos activos;
  - últimas 20 reservas.
- Un correo sugerido según el segmento. El dueño lo revisa y lo envía desde su propio correo;
  la app no envía nada sola.
- El dueño (`ADMIN_TENANT`) ve todo el lavadero. El admin de sucursal (`ADMIN_SUCURSAL`) solo ve
  a los clientes que reservaron en su sucursal, y solo las cifras de esa sucursal.

## Segmentos

Se evalúan en orden y gana el primero que aplica (ver `SegmentoCliente.java`):

| Segmento | Regla |
|---|---|
| Sin visitas | Ningún servicio completado (solo cuenta, o reservas pendientes o canceladas) |
| En riesgo | No tiene una próxima reserva y su última visita fue hace más del **doble de su intervalo promedio entre visitas**, con un mínimo de 30 días. Con una sola visita, más de 60 días |
| Nuevo | Su primera visita fue hace menos de 30 días |
| Frecuente | 4 visitas o más y vuelve, en promedio, cada 30 días o menos |
| Ocasional | El resto |

"En riesgo" depende del ritmo de cada cliente y no de un número fijo. Si alguien lava cada semana,
tres semanas sin venir ya es raro. Si alguien viene cada 40 días, a los 50 días todavía es normal:
su umbral es 80 días. Tener una reserva pendiente lo saca de riesgo, porque ya va a volver.

## Diseño técnico

El CRM vive en `modules/scheduling` porque es una lectura de `reserva`. No escribe nada.

| Pieza | Decisión |
|---|---|
| Modelo de lectura (`domain/model/crm`) | Records sin identidad (`ClienteResumen`, `PaginaClientes`, `VisitaCliente`), igual que `ResumenVentas`. El puerto `ClienteCrmRepository` está en el dominio |
| SQL directo (`ClienteCrmRepositoryAdapter`) | Usa `NamedParameterJdbcTemplate` y no JPA. Una consulta con CTE agrega las reservas por cliente con `count/sum/min/max ... filter (where ...)` y calcula el segmento con un `case` |
| Segmento en SQL, no en Java | Para filtrar, contar y paginar por segmento en Postgres. En Java habría que traer a todos los clientes para paginar. Los umbrales son constantes de `SegmentoCliente` que viajan como parámetros, así el número está en un solo lugar |
| SQL seguro | El texto del SQL se arma solo con fragmentos fijos: el join según haya sucursal, el filtro de búsqueda y un `ORDER BY` de una lista cerrada. Los valores van como parámetros. En la búsqueda, `%` y `_` se escapan para que sean literales |
| RLS | La consulta corre en la transacción del caso de uso: `TenantAwareTransactionAspect` ya fijó `app.current_tenant_id`, así que RLS acota `usuario`, `reserva` y `vehiculo` igual que con JPA. Un cliente de otro lavadero responde 404 |
| Conteo por segmento | Respeta la búsqueda y la sucursal, pero no el segmento elegido: los filtros muestran cuántos hay en cada segmento mientras se mira otro. El total de la página sale de ese mismo conteo, sin un `count(*)` extra |
| Índices | Reusa `idx_reserva_tenant_id`, `idx_reserva_sucursal_horario` (para la sucursal) e `idx_reserva_cliente_fecha` (para el historial). No hay migración nueva |
| Parámetros inválidos | `segmento` y `orden` llegan como texto y se validan en el controller. Un valor desconocido da un 400 que lista los valores válidos. `tamano` va de 1 a 100 y la búsqueda tiene máximo 100 caracteres |
| Reloj | "Ahora" sale del `Clock` inyectado, para que la segmentación sea reproducible en los tests |

Endpoints (roles `ADMIN_TENANT` y `ADMIN_SUCURSAL`):

- `GET /api/v1/crm/clientes?segmento=&q=&orden=ULTIMA_VISITA|GASTO|VISITAS|NOMBRE&sucursalId=&pagina=0&tamano=25`
- `GET /api/v1/crm/clientes/{id}?sucursalId=`

Costo: la lista agrega todas las reservas del lavadero en cada consulta (O(reservas del tenant)),
que alcanza de sobra para el volumen de un lavadero. Si un tenant llega a cientos de miles de
reservas, el siguiente paso es una vista materializada por cliente que se refresque al completar
reservas, o el evento `ReservaCompletada` de la fase de Kafka.

## Apps

- **`lavadero_core`:**
  - `SegmentoCliente` con su nombre y explicación en español, y `OrdenClientes`.
  - `ClienteCrm`, `PaginaClientes`, `VisitaCliente` y `FichaCliente`.
  - `CrmRepository`.
- **`admin_web`** (la pantalla reemplaza el placeholder):
  - Filtros por segmento con su conteo (explicación al pasar el cursor).
  - Aviso "Clientes en riesgo" que filtra con un clic.
  - Buscador con espera de 350 ms; si una respuesta vieja llega después de una búsqueda más
    nueva, se descarta.
  - Orden.
  - Tabla con "Cargar más".
  - Ficha en un diálogo, con el botón "Escribirle", que abre un `mailto:` con el mensaje del
    segmento ya escrito.

## Fuera de alcance

- Envío automático de correos o WhatsApp: requiere teléfono del cliente, consentimiento y un
  proveedor.
- Notas y etiquetas manuales por cliente.
- Exportar a CSV.
