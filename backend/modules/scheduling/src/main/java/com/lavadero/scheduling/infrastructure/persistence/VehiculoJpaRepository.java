package com.lavadero.scheduling.infrastructure.persistence;

import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

interface VehiculoJpaRepository extends JpaRepository<VehiculoJpaEntity, UUID> {

  List<VehiculoJpaEntity> findByClienteIdAndActivoTrueOrderByCreadoEnDesc(UUID clienteId);

  boolean existsByClienteIdAndPlacaAndActivoTrue(UUID clienteId, String placa);
}
