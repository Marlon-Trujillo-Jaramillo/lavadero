package com.lavadero.inventory.application.command;

import com.lavadero.inventory.domain.model.UnidadMedida;
import java.math.BigDecimal;

public record CrearInsumoCommand(String nombre, UnidadMedida unidad, BigDecimal costoUnitario) {}
