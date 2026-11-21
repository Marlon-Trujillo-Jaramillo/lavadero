package com.lavadero.inventory.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.application.usecase.ListarServiciosUseCase;
import com.lavadero.inventory.application.dto.CostoServicioDto;
import com.lavadero.inventory.domain.model.Insumo;
import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import com.lavadero.inventory.domain.repository.RecetaRepository;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * "Costo por lavado": para cada servicio, lo que cuestan los insumos de su receta y el margen que
 * deja frente a su precio. Tres consultas (servicios, insumos, recetas), sin N+1.
 */
@Service
public class ListarCostosPorServicioUseCase {

  private final ListarServiciosUseCase listarServiciosUseCase;
  private final InsumoRepository insumoRepository;
  private final RecetaRepository recetaRepository;

  public ListarCostosPorServicioUseCase(
      ListarServiciosUseCase listarServiciosUseCase,
      InsumoRepository insumoRepository,
      RecetaRepository recetaRepository) {
    this.listarServiciosUseCase = listarServiciosUseCase;
    this.insumoRepository = insumoRepository;
    this.recetaRepository = recetaRepository;
  }

  @Transactional(readOnly = true)
  public List<CostoServicioDto> execute() {
    Map<java.util.UUID, Insumo> insumos =
        insumoRepository.listarActivos().stream()
            .collect(Collectors.toMap(Insumo::getId, Function.identity()));
    Map<java.util.UUID, List<LineaReceta>> recetas = recetaRepository.todas();
    return listarServiciosUseCase.execute(null).stream()
        .map(s -> costo(s, recetas.getOrDefault(s.id(), List.of()), insumos))
        .toList();
  }

  static CostoServicioDto costo(
      ServicioDto servicio, List<LineaReceta> receta, Map<java.util.UUID, Insumo> insumos) {
    List<CostoServicioDto.Linea> lineas =
        receta.stream()
            .filter(l -> insumos.containsKey(l.insumoId()))
            .map(
                l -> {
                  Insumo insumo = insumos.get(l.insumoId());
                  return new CostoServicioDto.Linea(
                      insumo.getId(),
                      insumo.getNombre(),
                      insumo.getUnidad().name(),
                      l.cantidad(),
                      insumo.costoDe(l.cantidad()).setScale(2, RoundingMode.HALF_UP));
                })
            .toList();
    BigDecimal costo =
        lineas.stream().map(CostoServicioDto.Linea::costo).reduce(BigDecimal.ZERO, BigDecimal::add);
    BigDecimal precio = servicio.precio();
    BigDecimal margen = precio.subtract(costo);
    Integer porcentaje =
        precio.signum() == 0
            ? null
            : margen
                .multiply(BigDecimal.valueOf(100))
                .divide(precio, 0, RoundingMode.HALF_UP)
                .intValue();
    return new CostoServicioDto(
        servicio.id(),
        servicio.nombre(),
        servicio.activo(),
        precio,
        servicio.moneda(),
        lineas,
        costo,
        margen,
        porcentaje);
  }
}
