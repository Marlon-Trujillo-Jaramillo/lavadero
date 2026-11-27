package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.gasto.Gasto;
import com.lavadero.shared.domain.Money;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

public interface GastoRepository {

  Gasto save(Gasto gasto);

  /** Gastos del rango [desde, hasta] (ambos inclusive), los más recientes primero. */
  List<Gasto> listar(LocalDate desde, LocalDate hasta, UUID sucursalId);

  /** Suma de los gastos del rango [desde, hasta] (ambos inclusive). Cero si no hay. */
  Money sumar(LocalDate desde, LocalDate hasta, UUID sucursalId);
}
