package com.lavadero.scheduling.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface IncidenciaJpaRepository extends JpaRepository<IncidenciaJpaEntity, UUID> {

  List<IncidenciaJpaEntity> findByReportadoPorUsuarioIdOrderByCreadoEnDesc(UUID usuarioId);
}
