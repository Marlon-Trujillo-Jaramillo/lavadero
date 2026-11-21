package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.CotizarReservaQuery;
import com.lavadero.scheduling.application.command.CrearPromocionCommand;
import com.lavadero.scheduling.application.usecase.CotizarReservaUseCase;
import com.lavadero.scheduling.application.usecase.CrearPromocionUseCase;
import com.lavadero.scheduling.application.usecase.DesactivarPromocionUseCase;
import com.lavadero.scheduling.application.usecase.ListarPromocionesUseCase;
import com.lavadero.scheduling.domain.model.promocion.TipoDescuento;
import com.lavadero.scheduling.domain.model.promocion.TipoPromocion;
import com.lavadero.scheduling.interfaces.rest.dto.CotizacionResponse;
import com.lavadero.scheduling.interfaces.rest.dto.CrearPromocionRequest;
import com.lavadero.scheduling.interfaces.rest.dto.PromocionResponse;
import jakarta.validation.Valid;
import java.net.URI;
import java.time.DayOfWeek;
import java.time.Instant;
import java.util.EnumSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Promociones — ver docs/specs/011-promociones.md. Las crea y desactiva el dueño; el admin de
 * sucursal las ve con sus resultados; el cliente cotiza el precio antes de reservar.
 */
@RestController
public class PromocionController {

  private final CrearPromocionUseCase crearPromocionUseCase;
  private final ListarPromocionesUseCase listarPromocionesUseCase;
  private final DesactivarPromocionUseCase desactivarPromocionUseCase;
  private final CotizarReservaUseCase cotizarReservaUseCase;

  public PromocionController(
      CrearPromocionUseCase crearPromocionUseCase,
      ListarPromocionesUseCase listarPromocionesUseCase,
      DesactivarPromocionUseCase desactivarPromocionUseCase,
      CotizarReservaUseCase cotizarReservaUseCase) {
    this.crearPromocionUseCase = crearPromocionUseCase;
    this.listarPromocionesUseCase = listarPromocionesUseCase;
    this.desactivarPromocionUseCase = desactivarPromocionUseCase;
    this.cotizarReservaUseCase = cotizarReservaUseCase;
  }

  @GetMapping("/api/v1/promociones")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<PromocionResponse> listar() {
    return listarPromocionesUseCase.execute().stream().map(PromocionResponse::from).toList();
  }

  @PostMapping("/api/v1/promociones")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ResponseEntity<PromocionResponse> crear(@Valid @RequestBody CrearPromocionRequest r) {
    var creada =
        crearPromocionUseCase.execute(
            new CrearPromocionCommand(
                r.nombre(),
                ParametrosEnum.requerido(TipoPromocion.class, r.tipo(), "tipo"),
                r.codigo(),
                ParametrosEnum.requerido(TipoDescuento.class, r.tipoDescuento(), "tipoDescuento"),
                r.valorDescuento(),
                null,
                dias(r.dias()),
                r.horaDesde(),
                r.horaHasta(),
                r.vigenteDesde(),
                r.vigenteHasta(),
                r.usosMaximos()));
    return ResponseEntity.created(URI.create("/api/v1/promociones/" + creada.id()))
        .body(PromocionResponse.from(creada));
  }

  @DeleteMapping("/api/v1/promociones/{id}")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ResponseEntity<Void> desactivar(@PathVariable UUID id) {
    desactivarPromocionUseCase.execute(id);
    return ResponseEntity.noContent().build();
  }

  /** Precio con la mejor promoción para ese servicio y hora; {@code cupon} es opcional. */
  @GetMapping("/api/v1/promociones/cotizacion")
  @PreAuthorize("hasRole('CLIENTE')")
  public CotizacionResponse cotizar(
      @RequestParam UUID servicioId,
      @RequestParam Instant fechaHoraInicio,
      @RequestParam(required = false) String cupon) {
    if (cupon != null && cupon.length() > 40) {
      cupon = cupon.substring(0, 40);
    }
    return CotizacionResponse.from(
        cotizarReservaUseCase.execute(new CotizarReservaQuery(servicioId, fechaHoraInicio, cupon)));
  }

  private static Set<DayOfWeek> dias(List<String> dias) {
    if (dias == null) {
      return null;
    }
    Set<DayOfWeek> resultado = EnumSet.noneOf(DayOfWeek.class);
    for (String dia : dias) {
      resultado.add(ParametrosEnum.requerido(DayOfWeek.class, dia, "dias"));
    }
    return resultado;
  }
}
