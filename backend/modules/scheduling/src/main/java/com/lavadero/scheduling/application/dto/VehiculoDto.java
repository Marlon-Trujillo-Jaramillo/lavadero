package com.lavadero.scheduling.application.dto;

import java.time.Instant;
import java.util.UUID;

public record VehiculoDto(
    UUID id, String placa, String tipo, String marca, String color, Instant creadoEn) {}
