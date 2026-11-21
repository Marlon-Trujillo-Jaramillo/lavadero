package com.lavadero.scheduling.infrastructure.persistence;

import com.lavadero.scheduling.domain.model.promocion.CodigoCupon;
import com.lavadero.scheduling.domain.model.promocion.Descuento;
import com.lavadero.scheduling.domain.model.promocion.FranjaHoraria;
import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.model.promocion.ResultadoPromocion;
import com.lavadero.scheduling.domain.model.promocion.TipoDescuento;
import com.lavadero.scheduling.domain.model.promocion.TipoPromocion;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.shared.domain.Money;
import java.util.Currency;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

@Repository
class PromocionRepositoryAdapter implements PromocionRepository {

  private final PromocionJpaRepository jpaRepository;

  PromocionRepositoryAdapter(PromocionJpaRepository jpaRepository) {
    this.jpaRepository = jpaRepository;
  }

  @Override
  @Transactional
  public Promocion save(Promocion promocion) {
    Descuento descuento = promocion.getDescuento();
    Optional<FranjaHoraria> franja = promocion.getFranja();
    jpaRepository.save(
        new PromocionJpaEntity(
            promocion.getId(),
            promocion.getTenantId(),
            promocion.getNombre(),
            promocion.getTipo().name(),
            promocion.getCodigo().map(CodigoCupon::valor).orElse(null),
            descuento.tipo().name(),
            descuento.valor(),
            descuento.moneda() == null ? null : descuento.moneda().getCurrencyCode(),
            franja.map(FranjaHoraria::mascara).orElse(null),
            franja.map(FranjaHoraria::desde).orElse(null),
            franja.map(FranjaHoraria::hasta).orElse(null),
            promocion.getVigenteDesde(),
            promocion.getVigenteHasta(),
            promocion.getUsosMaximos().orElse(null),
            promocion.getUsos(),
            promocion.isActiva(),
            promocion.getCreadaEn()));
    return promocion;
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Promocion> findById(UUID id) {
    return jpaRepository.findById(id).map(PromocionRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public Optional<Promocion> findCuponActivo(CodigoCupon codigo) {
    return jpaRepository
        .findByCodigoAndActivaTrue(codigo.valor())
        .map(PromocionRepositoryAdapter::toDomain);
  }

  @Override
  @Transactional(readOnly = true)
  public List<Promocion> findHorariosActivos() {
    return jpaRepository.findByTipoAndActivaTrue(TipoPromocion.HORARIO.name()).stream()
        .map(PromocionRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional(readOnly = true)
  public List<Promocion> listar() {
    return jpaRepository.findAllByOrderByCreadaEnDesc().stream()
        .map(PromocionRepositoryAdapter::toDomain)
        .toList();
  }

  @Override
  @Transactional
  public boolean reservarUso(UUID promocionId) {
    return jpaRepository.reservarUso(promocionId) == 1;
  }

  @Override
  @Transactional
  public void liberarUso(UUID promocionId) {
    jpaRepository.liberarUso(promocionId);
  }

  @Override
  @Transactional(readOnly = true)
  public Map<UUID, ResultadoPromocion> resultados() {
    return jpaRepository.resultados().stream()
        .collect(
            Collectors.toMap(
                PromocionJpaRepository.ResultadoProjection::getPromocionId,
                r ->
                    new ResultadoPromocion(
                        r.getReservas(),
                        r.getCompletadas(),
                        Money.de(r.getIngresos(), r.getMoneda()),
                        Money.de(r.getDescuento(), r.getMoneda()))));
  }

  private static Promocion toDomain(PromocionJpaEntity e) {
    TipoDescuento tipoDescuento = TipoDescuento.valueOf(e.getTipoDescuento());
    Descuento descuento =
        new Descuento(
            tipoDescuento,
            e.getValorDescuento(),
            e.getMoneda() == null ? null : Currency.getInstance(e.getMoneda()));
    FranjaHoraria franja =
        e.getDiasSemana() == null
            ? null
            : new FranjaHoraria(
                FranjaHoraria.diasDeMascara(e.getDiasSemana()), e.getHoraDesde(), e.getHoraHasta());
    return new Promocion(
        e.getId(),
        e.getTenantId(),
        e.getNombre(),
        TipoPromocion.valueOf(e.getTipo()),
        e.getCodigo() == null ? null : new CodigoCupon(e.getCodigo()),
        descuento,
        franja,
        e.getVigenteDesde(),
        e.getVigenteHasta(),
        e.getUsosMaximos(),
        e.getUsos(),
        e.isActiva(),
        e.getCreadaEn());
  }
}
