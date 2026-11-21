package com.lavadero.inventory.application.usecase;

import com.lavadero.catalog.application.usecase.ObtenerServicioPorIdUseCase;
import com.lavadero.inventory.application.command.DefinirRecetaCommand;
import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.inventory.domain.repository.RecetaRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.TenantContext;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Define cuánto gasta un servicio de cada insumo. Reemplaza la receta completa. El servicio se
 * valida con el caso de uso de `catalog` (404 si no es del lavadero); los insumos, aquí.
 */
@Service
public class DefinirRecetaUseCase implements UseCase<DefinirRecetaCommand, Void> {

  static final int LINEAS_MAXIMAS = 20;

  private final ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase;
  private final InsumoRepository insumoRepository;
  private final RecetaRepository recetaRepository;

  public DefinirRecetaUseCase(
      ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase,
      InsumoRepository insumoRepository,
      RecetaRepository recetaRepository) {
    this.obtenerServicioPorIdUseCase = obtenerServicioPorIdUseCase;
    this.insumoRepository = insumoRepository;
    this.recetaRepository = recetaRepository;
  }

  @Override
  @Transactional
  public Void execute(DefinirRecetaCommand input) {
    obtenerServicioPorIdUseCase.execute(input.servicioId());
    List<LineaReceta> lineas = input.lineas();
    if (lineas.size() > LINEAS_MAXIMAS) {
      throw new ValidationException(
          "Una receta admite hasta " + LINEAS_MAXIMAS + " insumos distintos");
    }
    Set<UUID> vistos = new HashSet<>();
    for (LineaReceta linea : lineas) {
      if (!vistos.add(linea.insumoId())) {
        throw new ValidationException("Un insumo aparece dos veces en la receta");
      }
      boolean activo =
          insumoRepository.findById(linea.insumoId()).map(i -> i.isActivo()).orElse(false);
      if (!activo) {
        throw new ValidationException("Uno de los insumos de la receta no existe");
      }
    }
    recetaRepository.reemplazar(TenantContext.requerido(), input.servicioId(), lineas);
    return null;
  }
}
