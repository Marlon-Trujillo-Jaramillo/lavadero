# Spec 011: Promociones

## Estado

Implementado (2026-11-20). `./gradlew build` verde: incluye `PromocionTest`,
`PromocionUseCasesTest` y `PromocionIntegrationTest` (Postgres real, con concurrencia), más el
chequeo automático de RLS. `flutter analyze --fatal-infos` y `flutter test` verdes en
`lavadero_core`, `mobile_app` y `admin_web`.

## Contexto

"Promociones" era un `ComingSoonPlaceholder` en la web del dueño. Prometía tres cosas:
- cupones por porcentaje o monto fijo con vencimiento;
- precios por horario automáticos para las horas de baja demanda;
- resultados por campaña.

## Requisitos

- **Cupón:** código (4 a 20 letras, números o guiones; se normaliza a mayúsculas), descuento,
  vigencia y máximo de usos opcional. El cliente lo escribe al reservar.
- **Precio por horario:** días de la semana y franja `[desde, hasta)` en hora local. Se aplica
  sola a las reservas que empiezan dentro de la franja.
- **Descuento:**
  - Por porcentaje: entero de 1 a 90 %. Se redondea a pesos enteros.
  - Por monto fijo: nunca deja el precio en negativo.
- **No se acumulan:** gana la que más descuenta. Así un cupón nunca empeora el precio que el
  cliente ya tenía por reservar en hora valle.
- El cliente ve el precio final antes de confirmar, y si un cupón no sirve, ve el motivo:
  - no existe;
  - venció;
  - empieza más adelante;
  - se agotó;
  - no aplica en ese horario.
- **Desactivar** una promoción no la borra. Las reservas hechas conservan su precio, y los
  resultados de la promoción se siguen viendo.
- **Resultados por promoción:**
  - reservas, sin contar canceladas;
  - completadas;
  - lo cobrado;
  - lo descontado.
- Solo el dueño (`ADMIN_TENANT`) crea y desactiva promociones. El admin de sucursal las ve con
  sus resultados.

## Diseño técnico

| Pieza | Decisión |
|---|---|
| Módulo | `scheduling`: la promoción solo existe para cambiar el precio de una `Reserva` (mismo criterio que las specs 006 y 009) |
| `Descuento`, `CodigoCupon`, `FranjaHoraria` | Value objects que validan su forma. Sus errores salen como 400 por el mapeo de excepciones de dominio de la spec 009 |
| `CotizadorPrecios` | Servicio de dominio puro que elige la mejor promoción entre las candidatas |
| `ResolvedorPromociones` | Lo comparten "cotizar" y "crear reserva", para que el precio mostrado y el cobrado salgan del mismo código |
| Reserva | Guarda `promocion_id` y `precio_lista`. `precio` sigue siendo lo cobrado, así que los reportes de ventas y el CRM no cambian |
| Límite de usos | `UPDATE promocion SET usos = usos + 1 WHERE id = ? AND activa AND (usos_maximos IS NULL OR usos < usos_maximos)`: si no actualiza ninguna fila, la reserva no se crea. Un `CHECK` en la tabla respalda la regla. Cancelar devuelve el uso |
| Contador seguro | `usos` es `updatable = false` en la entidad JPA. Guardar el agregado (p. ej. al desactivar) nunca pisa el contador con un valor viejo en memoria |
| Código único | Índice único parcial `(tenant_id, codigo) WHERE activa`: dos lavaderos pueden usar "BIENVENIDA", y un código desactivado se puede reutilizar |
| Zona horaria | `America/Bogota` como constante del dominio (`Promocion.ZONA_HORARIA`), porque todos los lavaderos cobran en COP. Cuando haya otro país, pasa a ser un dato del tenant |
| Resultados | Una consulta agrupada por `promocion_id`. La lista son dos consultas en total, sin N+1 |

### Hallazgos corregidos en el camino

- **Centavos:** Java da 2 decimales para COP (ISO 4217), pero en Colombia se cobra en pesos
  enteros. Un 15 % sobre $33.333 daba $4.999,95. `Descuento` redondea a la unidad que se cobra de
  verdad, con la misma lista de monedas sin centavos que `Formato` en las apps.
- **Errores de forma de la petición respondían 500:** un query param mal formado
  (`servicioId=abc`, una fecha inválida), uno obligatorio faltante y un JSON ilegible (p. ej. una
  hora `"25:00"`) caían en el 500 genérico. Esto afectaba también a endpoints existentes, como
  reportes. `GlobalExceptionHandler` ahora los responde con un 400 que nombra el parámetro, sin
  exponer el detalle del parser.
- **Botones del formulario:** el pie de `LavaderoFormDialog` era un `Row` y se desbordaba con
  etiquetas largas o en pantallas angostas. Ahora es un `Wrap`.

## Endpoints

- `GET /api/v1/promociones` (`ADMIN_TENANT`, `ADMIN_SUCURSAL`): lista con resultados.
- `POST /api/v1/promociones` (`ADMIN_TENANT`). El cuerpo lleva `nombre`, `tipo`, `tipoDescuento`,
  `valorDescuento` y `vigenteDesde`/`vigenteHasta`. Además:
  - un cupón lleva `codigo` y, si quiere, `usosMaximos`;
  - un precio por horario lleva `dias`, `horaDesde` y `horaHasta`.
- `DELETE /api/v1/promociones/{id}` (`ADMIN_TENANT`): desactiva.
- `GET /api/v1/promociones/cotizacion?servicioId=&fechaHoraInicio=&cupon=` (`CLIENTE`).
- `POST /api/v1/agenda/reservas` acepta `codigoCupon`. `ReservaResponse` trae `promocionId` y
  `precioLista`.

## Apps

- **`lavadero_core`:**
  - `Promocion`, `Cotizacion`, `TipoPromocion`, `TipoDescuento` y `DiaSemana`.
  - `PromocionRepository`.
  - `Reserva.descuento`.
  - `SchedulingRepository.crear(codigoCupon:)`.
- **`mobile_app`:** al elegir servicio y hora, la app cotiza.
  - La barra inferior muestra el precio final, el de lista tachado y el nombre de la promoción.
  - Paso "Cupón (opcional)" detrás de "¿Tienes un cupón?", con el motivo si no sirve.
  - Si el cupón deja de servir al cambiar de hora, se quita y se explica por qué.
  - Si una respuesta vieja llega después de cambiar de hora, se descarta.
  - La confirmación muestra el descuento.
- **`admin_web`** (la pantalla reemplaza el placeholder):
  - Tarjetas con el descuento, la franja o el código, la vigencia y los usos.
  - Estado: Activa, Programada, Agotada, Vencida o Inactiva.
  - Resultados: reservas, cobrado y descontado.
  - Formulario para crear un precio por horario o un cupón.
  - Desactivar, con confirmación.

## Fuera de alcance

- Promociones por servicio o por sucursal: hoy aplican a todo el catálogo.
- Un uso por cliente.
- Mostrar en la lista de horas cuáles tienen descuento: hoy se ve al elegir la hora.
