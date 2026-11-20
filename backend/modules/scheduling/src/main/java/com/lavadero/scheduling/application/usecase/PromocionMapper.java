package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.dto.CotizacionDto;
import com.lavadero.scheduling.application.dto.PromocionDto;
import com.lavadero.scheduling.domain.model.promocion.CodigoCupon;
import com.lavadero.scheduling.domain.model.promocion.FranjaHoraria;
import com.lavadero.scheduling.domain.model.promocion.PrecioCotizado;
import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.model.promocion.ResultadoPromocion;
import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.util.List;

final class PromocionMapper {

  private PromocionMapper() {}

  static PromocionDto toDto(Promocion p, ResultadoPromocion resultado) {
    var franja = p.getFranja();
    return new PromocionDto(
        p.getId(),
        p.getNombre(),
        p.getTipo().name(),
        p.getCodigo().map(CodigoCupon::valor).orElse(null),
        p.getDescuento().tipo().name(),
        p.getDescuento().valor(),
        p.getDescuento().moneda() == null ? null : p.getDescuento().moneda().getCurrencyCode(),
        franja.map(f -> f.dias().stream().sorted().map(DayOfWeek::name).toList()).orElse(List.of()),
        franja.map(FranjaHoraria::desde).orElse(null),
        franja.map(FranjaHoraria::hasta).orElse(null),
        p.getVigenteDesde(),
        p.getVigenteHasta(),
        p.getUsosMaximos().orElse(null),
        p.getUsos(),
        p.isActiva(),
        p.getCreadaEn(),
        resultado == null ? 0 : resultado.reservas(),
        resultado == null ? 0 : resultado.completadas(),
        resultado == null ? BigDecimal.ZERO : resultado.ingresos().monto(),
        resultado == null ? BigDecimal.ZERO : resultado.descuentoOtorgado().monto());
  }

  static CotizacionDto toDto(PrecioCotizado c) {
    return new CotizacionDto(
        c.precioLista().monto(),
        c.descuento().monto(),
        c.precioFinal().monto(),
        c.precioLista().moneda().getCurrencyCode(),
        c.getPromocion().map(Promocion::getId).orElse(null),
        c.getPromocion().map(Promocion::getNombre).orElse(null));
  }
}
