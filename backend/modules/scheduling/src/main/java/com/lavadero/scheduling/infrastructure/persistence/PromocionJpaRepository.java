package com.lavadero.scheduling.infrastructure.persistence;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

interface PromocionJpaRepository extends JpaRepository<PromocionJpaEntity, UUID> {

  Optional<PromocionJpaEntity> findByCodigoAndActivaTrue(String codigo);

  List<PromocionJpaEntity> findByTipoAndActivaTrue(String tipo);

  List<PromocionJpaEntity> findAllByOrderByCreadaEnDesc();

  @Modifying
  @Query(
      nativeQuery = true,
      value =
          "update promocion set usos = usos + 1 "
              + "where id = :id and activa and (usos_maximos is null or usos < usos_maximos)")
  int reservarUso(@Param("id") UUID id);

  @Modifying
  @Query(
      nativeQuery = true,
      value = "update promocion set usos = usos - 1 where id = :id and usos > 0")
  int liberarUso(@Param("id") UUID id);

  @Query(
      nativeQuery = true,
      value =
          "select r.promocion_id as promocionId, count(*) as reservas, "
              + "count(*) filter (where r.estado = 'COMPLETADA') as completadas, "
              + "coalesce(sum(r.precio) filter (where r.estado = 'COMPLETADA'), 0) as ingresos, "
              + "coalesce(sum(r.precio_lista - r.precio), 0) as descuento, "
              + "min(r.moneda) as moneda "
              + "from reserva r "
              + "where r.promocion_id is not null and r.estado <> 'CANCELADA' "
              + "group by r.promocion_id")
  List<ResultadoProjection> resultados();

  interface ResultadoProjection {
    UUID getPromocionId();

    Long getReservas();

    Long getCompletadas();

    BigDecimal getIngresos();

    BigDecimal getDescuento();

    String getMoneda();
  }
}
