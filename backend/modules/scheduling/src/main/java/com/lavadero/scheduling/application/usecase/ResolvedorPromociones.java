package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.domain.model.promocion.CodigoCupon;
import com.lavadero.scheduling.domain.model.promocion.CotizadorPrecios;
import com.lavadero.scheduling.domain.model.promocion.PrecioCotizado;
import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import org.springframework.stereotype.Component;

/**
 * Lo que comparten "cotizar" y "crear reserva": reúne las candidatas (franjas horarias activas y el
 * cupón escrito, si hay) y deja que {@link CotizadorPrecios} elija. Un cupón que no existe o no
 * aplica es un 400 con el motivo, no un precio sin descuento en silencio: el cliente escribió un
 * código y merece saber por qué no funcionó.
 */
@Component
class ResolvedorPromociones {

  private final PromocionRepository promocionRepository;

  ResolvedorPromociones(PromocionRepository promocionRepository) {
    this.promocionRepository = promocionRepository;
  }

  PrecioCotizado cotizar(Money precioLista, Instant inicio, String codigoCupon) {
    List<Promocion> candidatas = new ArrayList<>(promocionRepository.findHorariosActivos());
    if (codigoCupon != null && !codigoCupon.isBlank()) {
      candidatas.add(cuponValido(codigoCupon, inicio));
    }
    return CotizadorPrecios.cotizar(precioLista, inicio, candidatas);
  }

  private Promocion cuponValido(String texto, Instant inicio) {
    CodigoCupon codigo;
    try {
      codigo = CodigoCupon.de(texto);
    } catch (IllegalArgumentException e) {
      throw new ValidationException("El cupón '%s' no existe".formatted(texto.strip()));
    }
    Promocion cupon =
        promocionRepository
            .findCuponActivo(codigo)
            .orElseThrow(
                () ->
                    new ValidationException(
                        "El cupón '%s' no existe o ya no está activo".formatted(codigo.valor())));
    cupon
        .motivoNoAplica(inicio)
        .ifPresent(
            motivo -> {
              throw new ValidationException(motivo);
            });
    return cupon;
  }
}
