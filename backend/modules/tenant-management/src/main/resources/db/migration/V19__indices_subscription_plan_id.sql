-- FKs a subscription_plan sin índice (convención: toda FK lleva el suyo). Sin ellos, borrar o
-- actualizar un plan escanea tenant y pago completas.
create index idx_tenant_subscription_plan_id on tenant (subscription_plan_id);
create index idx_pago_subscription_plan_id on pago (subscription_plan_id);
