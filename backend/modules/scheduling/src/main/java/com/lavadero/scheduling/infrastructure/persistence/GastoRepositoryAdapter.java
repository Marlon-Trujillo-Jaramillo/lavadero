package com.lavadero.scheduling.infrastructure.persistence;

import com.lavadero.scheduling.domain.model.gasto.CategoriaGasto;
import com.lavadero.scheduling.domain.model.gasto.Gasto;
import com.lavadero.scheduling.domain.repository.GastoRepository;
import com.lavadero.shared.domain.Money;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class GastoRepositoryAdapter implements GastoRepository {

  private final GastoJpaRepository jpaRepository;

  GastoRepositoryAdapter(GastoJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional
  public Gasto save(Gasto gasto) {
    jpaRepository.save(
        new GastoJpaEntity(
            gasto.getId(),
            gasto.getTenantId(),
            gasto.getSucursalId().orElse(null),
            gasto.getFecha(),
            gasto.getCategoria().name(),
            gasto.getDescripcion(),
            gasto.getMonto().monto(),
            gasto.getMonto().moneda().getCurrencyCode(),
            gasto.getCreadoEn()));
    return gasto;
  }

  @Override
  @Transactional(readOnly = true)
  public List<Gasto> listar(LocalDate desde, LocalDate hasta, UUID sucursalId) {
    return jpaRepository.listar(desde, hasta, sucursalId).stream()
        .map(GastoRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public Money sumar(LocalDate desde, LocalDate hasta, UUID sucursalId) {
    return Money.cop(jpaRepository.sumar(desde, hasta, sucursalId));
  }

  private static Gasto toDomain(GastoJpaEntity e) {
    return new Gasto(
        e.getId(),
        e.getTenantId(),
        e.getSucursalId(),
        e.getFecha(),
        CategoriaGasto.valueOf(e.getCategoria()),
        e.getDescripcion(),
        Money.de(e.getMonto(), e.getMoneda()),
        e.getCreadoEn());
  }
}
