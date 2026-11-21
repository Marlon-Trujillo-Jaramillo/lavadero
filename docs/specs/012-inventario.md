# Spec 012: Inventario de insumos

## Estado

Implementado (2026-11-20). `./gradlew build` verde:
- `InventarioDominioTest`, `ListarCostosPorServicioUseCaseTest` e `InventarioIntegrationTest`
  (Postgres real, con concurrencia y el evento con rollback).
- La regla nueva de ArchUnit (ningún módulo depende de `inventory`).
- El chequeo de RLS de todas las migraciones, que ahora incluye V24.

`flutter analyze --fatal-infos` y `flutter test` verdes en `lavadero_core` y `admin_web`.

## Contexto

"Inventario" era el último `ComingSoonPlaceholder`. Prometía tres cosas:
- stock por sucursal;
- alertas de reposición;
- costo por lavado.

## Requisitos

- **Insumos:** el dueño crea insumos con su unidad (ml, g o unidades) y su costo.
  - El formulario pide lo que el dueño sabe: "pagué $40.000 por 4.000 ml". El costo de 1 ml se
    calcula ahí.
  - La pantalla lo muestra por litro o por kilo.
- **Stock por sucursal:**
  - **Entradas:** lo que llega, con una nota opcional (p. ej. el número de factura).
  - **Conteo físico:** el stock pasa a ser lo contado y queda registrada la diferencia.
  - **Mínimo para alertar:** un insumo en o bajo su mínimo sale primero, marcado "Reponer".
- **Receta:** cuánto gasta cada servicio de cada insumo.
  - **Al completar un lavado, se descuenta solo de la sucursal donde se hizo.**
- **Kardex:** cada movimiento (entrada, consumo o ajuste) con su saldo.
- **Costo por lavado:** costo de los insumos de cada servicio, el margen frente a su precio y el
  porcentaje.
- El admin de sucursal registra entradas, conteos y mínimos de su sucursal. Crear insumos y
  editar recetas es del dueño.
- **Terminar un lavado nunca falla por el inventario:** el stock puede quedar negativo. Eso es una
  señal de que hay que contar la bodega, no un error.

## Diseño técnico

`inventory` es un **bounded context nuevo** (`modules/inventory`), el primero desde el monolito
inicial. Insumos, stock y kardex son un modelo propio. Meterlos en `scheduling` habría juntado dos
razones de cambio distintas.

| Pieza | Decisión |
|---|---|
| Dependencias | Conoce `catalog` por su capa `application` (validar servicios, leer precios) y `tenant`/`sucursal` solo por FK. **No depende de `scheduling`**: escucha su evento. ArchUnit lo verifica en las dos direcciones: inventory no usa scheduling, y ningún módulo usa inventory |
| `ReservaCompletadaEvent` (en `contracts`) | `CompletarReservaUseCase` lo publica después de guardar. El evento vive en `contracts`, que es el lugar de los eventos entre módulos (como `TenantCreadoEvent`) |
| Escucha `BEFORE_COMMIT` | El consumo corre en la misma transacción que completó la reserva. Se confirman juntos o ninguno: no hay lavado completado sin su consumo, ni consumo de un lavado que se revirtió. El test lo prueba con un rollback |
| Idempotencia | El caso de uso no hace nada si la reserva ya descontó. El índice único parcial `(reserva_id, insumo_id) WHERE tipo = 'CONSUMO'` respalda la regla. Hoy el evento llega una sola vez; con Kafka la entrega será "al menos una vez" y esto ya está listo |
| Stock atómico | `INSERT ... ON CONFLICT DO UPDATE SET cantidad = cantidad + delta RETURNING cantidad`, sin leer en Java y guardar. El test lanza 20 lavados simultáneos y no se pierde ningún descuento. El conteo físico bloquea la fila (`FOR UPDATE`) entre leer lo anterior y escribir lo contado |
| SQL directo | `NamedParameterJdbcTemplate` y no JPA: las escrituras importantes son UPSERTs atómicos que JPA no expresa bien. RLS aplica igual, porque corre en la transacción del caso de uso |
| Costo con 4 decimales | 1 ml de shampoo cuesta centavos, así que el costo no es un `Money` (que redondea a 2 decimales). El costo de cada línea de receta sí se redondea a 2 decimales para mostrarlo |
| Sin FK a `reserva` | `movimiento_inventario.reserva_id` es una referencia, no una FK. inventory no depende de scheduling, tampoco en el esquema |
| RLS | Las 4 tablas tienen RLS forzada y política con `nullif`. `scheduling` trae `inventory` como `testRuntimeOnly`, para que `RlsPoliticasIntegrationTest` revise todas las migraciones |

## Endpoints

| Método y ruta | Rol | Para qué |
|---|---|---|
| `GET /api/v1/inventario/insumos?sucursalId=` | Ambos admins | Stock de la sucursal (el admin de sucursal siempre ve la suya) |
| `POST /api/v1/inventario/insumos` | `ADMIN_TENANT` | Crear insumo: `{nombre, unidad, costoUnitario}` |
| `POST /api/v1/inventario/insumos/{id}/entradas` | Ambos admins | Entrada |
| `POST /api/v1/inventario/insumos/{id}/ajustes` | Ambos admins | Conteo físico |
| `PUT /api/v1/inventario/insumos/{id}/minimo` | Ambos admins | Mínimo para alertar |
| `GET /api/v1/inventario/insumos/{id}/movimientos?sucursalId=` | Ambos admins | Kardex (últimos 50) |
| `GET /api/v1/inventario/costos` | Ambos admins | Costo por servicio |
| `PUT /api/v1/inventario/recetas/{servicioId}` | `ADMIN_TENANT` | Reemplazar la receta: `{lineas: [{insumoId, cantidad}]}` |

Entradas, ajustes y mínimo reciben `{sucursalId, cantidad, nota?}`.

## Apps

- **`lavadero_core`:**
  - `UnidadMedida`, `InsumoStock`, `MovimientoInventario`, `CostoServicio` y `LineaCosto`.
  - `InventarioRepository`.
- **`admin_web`** (la pantalla reemplaza el placeholder):
  - Vista "Stock":
    - KPIs: insumos, por reponer, valor en bodega.
    - Selector de sucursal.
    - Tabla con entrada, conteo, mínimo y kardex.
    - "Nuevo insumo" con stock inicial y mínimo.
  - Vista "Costo por lavado": tarjetas con la receta, el costo y el margen, más el editor de
    receta.
  - Los números aceptan miles con punto ("1.500") y decimales con coma ("0,5").

## Siguiente paso: Kafka

`ReservaCompletadaEvent` es el primer candidato para el outbox transaccional:
1. `CompletarReservaUseCase` escribe el evento en una tabla `outbox` en su transacción.
2. Un publicador lo manda a Kafka.
3. `inventory` lo consume de forma asíncrona.

La idempotencia ya existe. Lo que cambia es que el consumo deja de ser atómico con la completación
y pasa a ser eventual.

## Fuera de alcance

- Traslados entre sucursales: hoy se hacen como un ajuste en una y una entrada en la otra.
- Proveedores y órdenes de compra.
- Consumo distinto por tipo de vehículo, p. ej. una camioneta gasta más.
