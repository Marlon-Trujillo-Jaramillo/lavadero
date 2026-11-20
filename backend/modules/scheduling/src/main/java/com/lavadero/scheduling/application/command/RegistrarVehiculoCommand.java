package com.lavadero.scheduling.application.command;

import com.lavadero.scheduling.domain.model.TipoVehiculo;
import java.util.UUID;

/** {@code clienteId} viene de {@code PrincipalAutenticado} en el controller, nunca del body. */
public record RegistrarVehiculoCommand(
    UUID clienteId, String placa, TipoVehiculo tipo, String marca, String color) {}
