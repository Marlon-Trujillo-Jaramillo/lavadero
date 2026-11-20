package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.CrearPromocionCommand;
import com.lavadero.scheduling.application.dto.PromocionDto;
import com.lavadero.scheduling.domain.model.promocion.CodigoCupon;
import com.lavadero.scheduling.domain.model.promocion.Descuento;
import com.lavadero.scheduling.domain.model.promocion.FranjaHoraria;
import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.model.promocion.TipoDescuento;
import com.lavadero.scheduling.domain.model.promocion.TipoPromocion;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import java.time.Clock;
import java.time.LocalDate;
import java.util.Currency;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Crea un cupón o un precio por horario. Las reglas de forma (porcentaje 1–90, código, franja,
 * vigencia) las valida el dominio y salen como 400; aquí van las que necesitan contexto: que la
 * vigencia no haya terminado ya y que el código no esté en uso en este lavadero.
 */
@Service
public class CrearPromocionUseCase implements UseCase<CrearPromocionCommand, PromocionDto> {

  private final PromocionRepository promocionRepository;
  private final Clock reloj;

  public CrearPromocionUseCase(PromocionRepository promocionRepository, Clock reloj) {
    this.promocionRepository = promocionRepository;
    this.reloj = reloj;
  }

  @Override
  @Transactional
  public PromocionDto execute(CrearPromocionCommand input) {
    LocalDate hoy = LocalDate.now(reloj.withZone(Promocion.ZONA_HORARIA));
    if (input.vigenteHasta().isBefore(hoy)) {
      throw new ValidationException("La vigencia ya terminó: elige una fecha final desde hoy");
    }
    Descuento descuento = descuento(input);
    Promocion promocion =
        input.tipo() == TipoPromocion.CUPON ? cupon(input, descuento) : horario(input, descuento);
    return PromocionMapper.toDto(promocionRepository.save(promocion), null);
  }

  private Promocion cupon(CrearPromocionCommand input, Descuento descuento) {
    if (input.codigo() == null || input.codigo().isBlank()) {
      throw new ValidationException("Un cupón necesita un código");
    }
    CodigoCupon codigo = CodigoCupon.de(input.codigo());
    if (promocionRepository.findCuponActivo(codigo).isPresent()) {
      throw new ValidationException(
          "Ya tienes un cupón activo con el código %s".formatted(codigo.valor()));
    }
    return Promocion.cupon(
        TenantContext.requerido(),
        input.nombre(),
        codigo,
        descuento,
        input.vigenteDesde(),
        input.vigenteHasta(),
        input.usosMaximos(),
        reloj.instant());
  }

  private Promocion horario(CrearPromocionCommand input, Descuento descuento) {
    if (input.dias() == null || input.horaDesde() == null || input.horaHasta() == null) {
      throw new ValidationException("Un precio por horario necesita días y horas");
    }
    return Promocion.horario(
        TenantContext.requerido(),
        input.nombre(),
        new FranjaHoraria(input.dias(), input.horaDesde(), input.horaHasta()),
        descuento,
        input.vigenteDesde(),
        input.vigenteHasta(),
        reloj.instant());
  }

  private static Descuento descuento(CrearPromocionCommand input) {
    if (input.tipoDescuento() == TipoDescuento.PORCENTAJE) {
      return new Descuento(TipoDescuento.PORCENTAJE, input.valorDescuento(), null);
    }
    String moneda = input.moneda() == null ? "COP" : input.moneda();
    return Descuento.montoFijo(Money.de(input.valorDescuento(), Currency.getInstance(moneda)));
  }
}
