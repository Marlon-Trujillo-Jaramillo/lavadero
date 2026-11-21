package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.FichaClienteQuery;
import com.lavadero.scheduling.application.command.ListarClientesQuery;
import com.lavadero.scheduling.application.usecase.ListarClientesUseCase;
import com.lavadero.scheduling.application.usecase.ObtenerFichaClienteUseCase;
import com.lavadero.scheduling.domain.model.crm.OrdenClientes;
import com.lavadero.scheduling.domain.model.crm.SegmentoCliente;
import com.lavadero.scheduling.interfaces.rest.dto.FichaClienteResponse;
import com.lavadero.scheduling.interfaces.rest.dto.PaginaClientesResponse;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.PrincipalAutenticado;
import java.util.UUID;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * CRM de clientes para el dueño (todo el lavadero) y el admin de sucursal (solo su sucursal) — ver
 * docs/specs/010-crm-clientes.md.
 */
@RestController
public class ClienteCrmController {

  private final ListarClientesUseCase listarClientesUseCase;
  private final ObtenerFichaClienteUseCase obtenerFichaClienteUseCase;

  public ClienteCrmController(
      ListarClientesUseCase listarClientesUseCase,
      ObtenerFichaClienteUseCase obtenerFichaClienteUseCase) {
    this.listarClientesUseCase = listarClientesUseCase;
    this.obtenerFichaClienteUseCase = obtenerFichaClienteUseCase;
  }

  /**
   * {@code segmento} y {@code orden} llegan como texto y se validan aquí: un valor desconocido es
   * un 400 con los valores válidos, no un error de conversión de Spring.
   */
  @GetMapping("/api/v1/crm/clientes")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public PaginaClientesResponse listar(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @RequestParam(required = false) String segmento,
      @RequestParam(required = false) String q,
      @RequestParam(required = false) String orden,
      @RequestParam(required = false) UUID sucursalId,
      @RequestParam(defaultValue = "0") int pagina,
      @RequestParam(defaultValue = "25") int tamano) {
    return PaginaClientesResponse.from(
        listarClientesUseCase.execute(
            new ListarClientesQuery(
                ParametrosEnum.opcional(SegmentoCliente.class, segmento, "segmento"),
                q,
                ParametrosEnum.opcional(OrdenClientes.class, orden, "orden"),
                sucursalId,
                pagina,
                tamano,
                AlcanceSucursal.de(principal))));
  }

  @GetMapping("/api/v1/crm/clientes/{clienteId}")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public FichaClienteResponse ficha(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @PathVariable UUID clienteId,
      @RequestParam(required = false) UUID sucursalId) {
    return FichaClienteResponse.from(
        obtenerFichaClienteUseCase.execute(
            new FichaClienteQuery(clienteId, sucursalId, AlcanceSucursal.de(principal))));
  }
}
