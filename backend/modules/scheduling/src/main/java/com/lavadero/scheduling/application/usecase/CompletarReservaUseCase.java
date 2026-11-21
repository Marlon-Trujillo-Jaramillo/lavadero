package com.lavadero.scheduling.application.usecase;

import com.lavadero.contracts.scheduling.ReservaCompletadaEvent;
import com.lavadero.scheduling.application.command.ReservaStaffCommand;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.shared.application.UseCase;
import java.time.Clock;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * El empleado marca el lavado como terminado y se publica {@link ReservaCompletadaEvent} (lo usa
 * `inventory` para descontar insumos, dentro de esta misma transacción).
 */
@Service
public class CompletarReservaUseCase implements UseCase<ReservaStaffCommand, ReservaDto> {

  private final ReservaRepository reservaRepository;
  private final ApplicationEventPublisher eventos;
  private final Clock reloj;

  public CompletarReservaUseCase(
      ReservaRepository reservaRepository, ApplicationEventPublisher eventos, Clock reloj) {
    this.reservaRepository = reservaRepository;
    this.eventos = eventos;
    this.reloj = reloj;
  }

  @Override
  @Transactional
  public ReservaDto execute(ReservaStaffCommand input) {
    Reserva reserva =
        ReservaDelAlcance.cargar(reservaRepository, input.reservaId(), input.alcance());
    reserva.completar();
    ReservaDto completada = ReservaMapper.toDto(reservaRepository.save(reserva));
    eventos.publishEvent(
        new ReservaCompletadaEvent(
            reserva.getId(),
            reserva.getTenantId(),
            reserva.getSucursalId(),
            reserva.getServicioId(),
            reloj.instant()));
    return completada;
  }
}
