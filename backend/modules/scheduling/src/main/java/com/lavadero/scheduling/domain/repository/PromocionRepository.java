package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.promocion.CodigoCupon;
import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.model.promocion.ResultadoPromocion;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;

public interface PromocionRepository {

  /**
   * No toca {@code usos}: ese contador solo cambia con {@link #reservarUso}/{@link #liberarUso}.
   */
  Promocion save(Promocion promocion);

  Optional<Promocion> findById(UUID id);

  Optional<Promocion> findCuponActivo(CodigoCupon codigo);

  List<Promocion> findHorariosActivos();

  /** Todas, las más nuevas primero. */
  List<Promocion> listar();

  /**
   * Suma un uso si la promoción sigue activa y no llegó a su máximo, en una sola sentencia atómica:
   * dos clientes que usan el último cupón a la vez no pueden pasar los dos. Devuelve {@code false}
   * si no quedaba cupo.
   */
  boolean reservarUso(UUID promocionId);

  /** Devuelve un uso (la reserva que lo gastó se canceló). */
  void liberarUso(UUID promocionId);

  /** Resultados de cada promoción que ya tiene reservas, por id. */
  Map<UUID, ResultadoPromocion> resultados();
}
