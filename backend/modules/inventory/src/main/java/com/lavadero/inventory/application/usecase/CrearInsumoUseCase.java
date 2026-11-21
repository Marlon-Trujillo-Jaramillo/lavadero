package com.lavadero.inventory.application.usecase;

import com.lavadero.inventory.application.command.CrearInsumoCommand;
import com.lavadero.inventory.domain.model.Insumo;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import java.time.Clock;
import java.util.Currency;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CrearInsumoUseCase implements UseCase<CrearInsumoCommand, UUID> {

  private final InsumoRepository insumoRepository;
  private final Clock reloj;

  public CrearInsumoUseCase(InsumoRepository insumoRepository, Clock reloj) {
    this.insumoRepository = insumoRepository;
    this.reloj = reloj;
  }

  @Override
  @Transactional
  public UUID execute(CrearInsumoCommand input) {
    if (input.nombre() != null && insumoRepository.existeActivoConNombre(input.nombre())) {
      throw new ValidationException(
          "Ya tienes un insumo llamado '%s'".formatted(input.nombre().strip()));
    }
    Insumo insumo =
        Insumo.nuevo(
            TenantContext.requerido(),
            input.nombre(),
            input.unidad(),
            input.costoUnitario(),
            Currency.getInstance("COP"),
            reloj.instant());
    return insumoRepository.save(insumo).getId();
  }
}
