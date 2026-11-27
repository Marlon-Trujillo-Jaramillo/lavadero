package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.RegistrarGastoCommand;
import com.lavadero.scheduling.application.dto.GastoDto;
import com.lavadero.scheduling.domain.model.gasto.Gasto;
import com.lavadero.scheduling.domain.repository.GastoRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import java.time.Clock;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Registra un gasto operativo del lavadero (opcionalmente imputado a una sucursal). */
@Service
public class RegistrarGastoUseCase implements UseCase<RegistrarGastoCommand, GastoDto> {

  private final GastoRepository gastoRepository;
  private final Clock reloj;

  public RegistrarGastoUseCase(GastoRepository gastoRepository, Clock reloj) {
    this.gastoRepository = gastoRepository;
    this.reloj = reloj;
  }

  @Override
  @Transactional
  public GastoDto execute(RegistrarGastoCommand input) {
    if (input.sucursalId() != null) {
      input.alcance().verificar(input.sucursalId());
    }
    String moneda = input.moneda() == null ? "COP" : input.moneda();
    Money monto = Money.de(input.monto(), moneda);
    Gasto gasto =
        Gasto.nuevo(
            TenantContext.requerido(),
            input.sucursalId(),
            input.fecha(),
            input.categoria(),
            input.descripcion(),
            monto,
            reloj.instant());
    return GastoMapper.toDto(gastoRepository.save(gasto));
  }
}
