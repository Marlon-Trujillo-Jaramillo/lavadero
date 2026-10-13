package com.lavadero.tenant.interfaces.rest;

import com.lavadero.tenant.application.command.IniciarPagoSuscripcionCommand;
import com.lavadero.tenant.application.command.ProcesarEventoPagoCommand;
import com.lavadero.tenant.application.dto.ResultadoEventoPago;
import com.lavadero.tenant.application.usecase.IniciarPagoSuscripcionUseCase;
import com.lavadero.tenant.application.usecase.ListarPagosUseCase;
import com.lavadero.tenant.application.usecase.ProcesarEventoWompiUseCase;
import com.lavadero.tenant.interfaces.rest.dto.CheckoutPagoResponse;
import com.lavadero.tenant.interfaces.rest.dto.IniciarPagoSuscripcionRequest;
import com.lavadero.tenant.interfaces.rest.dto.PagoResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Cobro de la suscripción del tenant vía Wompi (Web Checkout + webhook de confirmación). */
@RestController
public class PagoController {

  static final int LIMITE_DEFECTO = 50;
  static final int LIMITE_MAXIMO = 200;

  private final IniciarPagoSuscripcionUseCase iniciarPagoSuscripcionUseCase;
  private final ListarPagosUseCase listarPagosUseCase;
  private final ProcesarEventoWompiUseCase procesarEventoWompiUseCase;

  public PagoController(
      IniciarPagoSuscripcionUseCase iniciarPagoSuscripcionUseCase,
      ListarPagosUseCase listarPagosUseCase,
      ProcesarEventoWompiUseCase procesarEventoWompiUseCase) {
    this.iniciarPagoSuscripcionUseCase = iniciarPagoSuscripcionUseCase;
    this.listarPagosUseCase = listarPagosUseCase;
    this.procesarEventoWompiUseCase = procesarEventoWompiUseCase;
  }

  @PostMapping("/api/v1/pagos/suscripcion")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ResponseEntity<CheckoutPagoResponse> iniciarSuscripcion(
      @Valid @RequestBody IniciarPagoSuscripcionRequest request) {
    var checkout =
        iniciarPagoSuscripcionUseCase.execute(
            new IniciarPagoSuscripcionCommand(request.subscriptionPlanId()));
    return ResponseEntity.status(HttpStatus.CREATED).body(CheckoutPagoResponse.from(checkout));
  }

  /** Más recientes primero; {@code limite} opcional (por defecto 50, se acota a [1, 200]). */
  @GetMapping("/api/v1/pagos")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public List<PagoResponse> listar(@RequestParam(required = false) Integer limite) {
    int limiteEfectivo = Math.clamp(limite == null ? LIMITE_DEFECTO : limite, 1, LIMITE_MAXIMO);
    return listarPagosUseCase.execute(limiteEfectivo).stream().map(PagoResponse::from).toList();
  }

  /**
   * Público (lista blanca de {@code SecurityConfig}): lo llama Wompi, sin JWT. El cuerpo se recibe
   * crudo porque la firma se verifica sobre él. Wompi reintenta todo lo que no sea 200, así que un
   * evento auténtico que se ignora igual responde 200; solo lo no auténtico/vencido se rechaza.
   */
  @PostMapping("/api/v1/pagos/webhook/wompi")
  public ResponseEntity<Void> webhookWompi(@RequestBody String payloadCrudo) {
    ResultadoEventoPago resultado =
        procesarEventoWompiUseCase.execute(new ProcesarEventoPagoCommand(payloadCrudo));
    HttpStatus status =
        switch (resultado) {
          case FIRMA_INVALIDA -> HttpStatus.UNAUTHORIZED;
          case EVENTO_VENCIDO -> HttpStatus.BAD_REQUEST;
          case IGNORADO, PROCESADO -> HttpStatus.OK;
        };
    return ResponseEntity.status(status).build();
  }
}
