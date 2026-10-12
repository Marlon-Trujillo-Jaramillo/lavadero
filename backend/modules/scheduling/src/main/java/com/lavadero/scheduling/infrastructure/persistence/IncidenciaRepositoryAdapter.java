package com.lavadero.scheduling.infrastructure.persistence;

import com.lavadero.scheduling.domain.model.Incidencia;
import com.lavadero.scheduling.domain.model.IncidenciaCategoria;
import com.lavadero.scheduling.domain.repository.IncidenciaRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class IncidenciaRepositoryAdapter implements IncidenciaRepository {

  private final IncidenciaJpaRepository jpaRepository;

  IncidenciaRepositoryAdapter(IncidenciaJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<Incidencia> findByReportadoPorUsuarioId(UUID usuarioId) {
    return jpaRepository.findByReportadoPorUsuarioIdOrderByCreadoEnDesc(usuarioId).stream()
        .map(IncidenciaRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional
  public Incidencia save(Incidencia incidencia) {
    IncidenciaJpaEntity entity =
        new IncidenciaJpaEntity(
            incidencia.getId(),
            incidencia.getTenantId(),
            incidencia.getSucursalId(),
            incidencia.getReservaId().orElse(null),
            incidencia.getReportadoPorUsuarioId(),
            incidencia.getCategoria().name(),
            incidencia.getDescripcion(),
            incidencia.getCreadoEn());
    jpaRepository.save(entity);
    return incidencia;
  }

  private static Incidencia toDomain(IncidenciaJpaEntity entity) {
    return new Incidencia(
        entity.getId(),
        entity.getTenantId(),
        entity.getSucursalId(),
        entity.getReservaId(),
        entity.getReportadoPorUsuarioId(),
        IncidenciaCategoria.valueOf(entity.getCategoria()),
        entity.getDescripcion(),
        entity.getCreadoEn());
  }
}
