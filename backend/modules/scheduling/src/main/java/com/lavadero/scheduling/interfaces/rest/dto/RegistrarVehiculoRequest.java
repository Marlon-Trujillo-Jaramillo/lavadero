package com.lavadero.scheduling.interfaces.rest.dto;

import com.lavadero.scheduling.domain.model.TipoVehiculo;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

/** El formato de la placa lo valida el dominio ({@code Placa}); aquí solo se acota el tamaño. */
public record RegistrarVehiculoRequest(
    @NotBlank(message = "Ingresa la placa") @Size(max = 12, message = "La placa es muy larga")
        String placa,
    @NotNull(message = "Elige el tipo de vehículo") TipoVehiculo tipo,
    @Size(max = 40, message = "La marca admite hasta 40 caracteres") String marca,
    @Size(max = 30, message = "El color admite hasta 30 caracteres") String color) {}
