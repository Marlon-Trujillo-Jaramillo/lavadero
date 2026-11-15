package com.lavadero.scheduling.infrastructure.persistence;

import com.lavadero.scheduling.domain.model.Placa;
import com.lavadero.scheduling.domain.model.TipoVehiculo;
import com.lavadero.scheduling.domain.model.Vehiculo;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class VehiculoRepositoryAdapter implements VehiculoRepository {

  private final VehiculoJpaRepository jpaRepository;

  VehiculoRepositoryAdapter(VehiculoJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional(readOnly = true)
  public List<Vehiculo> findActivosByClienteId(UUID clienteId) {
    return jpaRepository.findByClienteIdAndActivoTrueOrderByCreadoEnDesc(clienteId).stream()
        .map(VehiculoRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Vehiculo> findById(UUID id) {
    return jpaRepository.findById(id).map(VehiculoRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public boolean existeActivoConPlaca(UUID clienteId, Placa placa) {
    return jpaRepository.existsByClienteIdAndPlacaAndActivoTrue(clienteId, placa.valor());
  }

  @Override
  @Transactional
  public Vehiculo save(Vehiculo vehiculo) {
    jpaRepository.save(
        new VehiculoJpaEntity(
            vehiculo.getId(),
            vehiculo.getTenantId(),
            vehiculo.getClienteId(),
            vehiculo.getPlaca().valor(),
            vehiculo.getTipo().name(),
            vehiculo.getMarca().orElse(null),
            vehiculo.getColor().orElse(null),
            vehiculo.isActivo(),
            vehiculo.getCreadoEn()));
    return vehiculo;
  }

  private static Vehiculo toDomain(VehiculoJpaEntity entity) {
    return new Vehiculo(
        entity.getId(),
        entity.getTenantId(),
        entity.getClienteId(),
        new Placa(entity.getPlaca()),
        TipoVehiculo.valueOf(entity.getTipo()),
        entity.getMarca(),
        entity.getColor(),
        entity.isActivo(),
        entity.getCreadoEn());
  }
}
