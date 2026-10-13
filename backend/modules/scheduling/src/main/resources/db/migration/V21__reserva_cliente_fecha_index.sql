-- `GET /agenda/reservas/mias` ahora ordena por fecha desc con límite: con (cliente_id,
-- fecha_hora_inicio desc) Postgres lee las N primeras filas del índice sin ordenar en memoria. El
-- índice compuesto también sirve para la FK `cliente_id` (columna líder), así que reemplaza al de
-- V13. `reserva` ya tiene RLS + FORCE + grant (V6/V11); un índice no cambia nada de eso.
create index idx_reserva_cliente_fecha on reserva (cliente_id, fecha_hora_inicio desc);
drop index idx_reserva_cliente_id;
