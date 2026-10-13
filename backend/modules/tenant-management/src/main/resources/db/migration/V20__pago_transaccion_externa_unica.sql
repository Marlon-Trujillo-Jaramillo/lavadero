-- Una transacción de la pasarela aprueba como máximo UN pago. Sin esto, un evento auténtico
-- reenviado con otra `reference` (la referencia no forma parte del checksum de Wompi) podría
-- aprobar un segundo pago con la misma transacción. Único global, no por tenant: el id lo asigna
-- Wompi. Los NULL (pagos PENDIENTE/RECHAZADO) no chocan entre sí en un índice único de Postgres.
-- `pago` ya tiene RLS + FORCE + grant (V14); este índice no cambia nada de eso.
create unique index uq_pago_transaccion_externa_id on pago (transaccion_externa_id);
