package com.lavadero.scheduling.application.command;

import com.lavadero.scheduling.domain.model.gasto.CategoriaGasto;
import com.lavadero.shared.security.AlcanceSucursal;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

/**
 * {@code sucursalId} es opcional ({@code null} = gasto general del negocio). {@code moneda} por
 * defecto COP. {@code alcance} limita a qué sucursal puede imputarse el gasto.
 */
public record RegistrarGastoCommand(
    UUID sucursalId,
    LocalDate fecha,
    CategoriaGasto categoria,
    String descripcion,
    BigDecimal monto,
    String moneda,
    AlcanceSucursal alcance) {}
