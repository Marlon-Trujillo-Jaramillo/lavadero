package com.lavadero.scheduling.infrastructure.persistence;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface GastoJpaRepository extends JpaRepository<GastoJpaEntity, UUID> {

  @Query(
      nativeQuery = true,
      value =
          "select * from gasto where fecha >= :desde and fecha <= :hasta "
              + "and (cast(:sucursalId as uuid) is null or sucursal_id = :sucursalId) "
              + "order by fecha desc, creado_en desc")
  List<GastoJpaEntity> listar(
      @Param("desde") LocalDate desde,
      @Param("hasta") LocalDate hasta,
      @Param("sucursalId") UUID sucursalId);

  @Query(
      nativeQuery = true,
      value =
          "select coalesce(sum(monto), 0) from gasto where fecha >= :desde and fecha <= :hasta "
              + "and (cast(:sucursalId as uuid) is null or sucursal_id = :sucursalId)")
  BigDecimal sumar(
      @Param("desde") LocalDate desde,
      @Param("hasta") LocalDate hasta,
      @Param("sucursalId") UUID sucursalId);
}
