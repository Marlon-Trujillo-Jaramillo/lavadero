package com.lavadero.tenant.application.dto;

import java.util.UUID;

/** Vista pública/resumida de un tenant: nada sensible (ni NIT, ni plan, ni estado interno). */
public record TenantResumenDto(UUID id, String slug, String nombre) {}
