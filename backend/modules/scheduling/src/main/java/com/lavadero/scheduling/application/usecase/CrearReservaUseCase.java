package com.lavadero.scheduling.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.application.usecase.ObtenerServicioPorIdUseCase;
import com.lavadero.scheduling.application.command.CrearReservaCommand;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.scheduling.domain.service.DisponibilidadService;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.application.usecase.ObtenerSucursalPorIdUseCase;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Crea una reserva del tenant actual, validando disponibilidad (capacidad de la sucursal en ese
 * horario, ver {@link DisponibilidadService}) y congelando precio/duración del servicio al momento
 * de reservar. Resuelve servicio/sucursal a través de la capa `application` de los módulos
 * `catalog`/`tenant-management` (no de sus repositorios de dominio directamente) — mismo patrón que
 * usa `identity-access` para llamar a `tenant-management` (ver `LoginUseCase`).
 */
@Service
public class CrearReservaUseCase implements UseCase<CrearReservaCommand, ReservaDto> {

  private final ReservaRepository reservaRepository;
  private final ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase;
  private final ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase;

  public CrearReservaUseCase(
      ReservaRepository reservaRepository,
      ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase,
      ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase) {
    this.reservaRepository = reservaRepository;
    this.obtenerServicioPorIdUseCase = obtenerServicioPorIdUseCase;
    this.obtenerSucursalPorIdUseCase = obtenerSucursalPorIdUseCase;
  }

  @Override
  @Transactional
  public ReservaDto execute(CrearReservaCommand input) {
    ServicioDto servicio = obtenerServicioPorIdUseCase.execute(input.servicioId());
    if (!servicio.activo()) {
      throw new ValidationException("El servicio '%s' no está activo".formatted(servicio.nombre()));
    }

    SucursalDto sucursal = obtenerSucursalPorIdUseCase.execute(input.sucursalId());

    Instant inicio = input.fechaHoraInicio();
    Instant fin = inicio.plus(Duration.ofMinutes(servicio.duracionEstimadaMinutos()));

    reservaRepository.bloquearAgendaDeSucursal(input.sucursalId());
    List<Reserva> activasEnRango =
        reservaRepository.findActivasPorSucursalYRango(input.sucursalId(), inicio, fin);
    boolean hayCupo =
        DisponibilidadService.hayCupo(sucursal.capacidadSimultanea(), activasEnRango, inicio, fin);
    if (!hayCupo) {
      throw new ValidationException("No hay cupo disponible en esa sucursal para ese horario");
    }

    Reserva reserva =
        Reserva.nueva(
            TenantContext.requerido(),
            input.sucursalId(),
            input.servicioId(),
            input.clienteId(),
            inicio,
            servicio.duracionEstimadaMinutos(),
            Money.de(servicio.precio(), servicio.moneda()));

    return ReservaMapper.toDto(reservaRepository.save(reserva));
  }
}
