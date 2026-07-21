package com.lavadero.tenant.interfaces.rest;

import com.lavadero.tenant.application.usecase.ListarSucursalesUseCase;
import com.lavadero.tenant.interfaces.rest.dto.SucursalResponse;
import java.util.List;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class SucursalController {

  private final ListarSucursalesUseCase listarSucursalesUseCase;

  public SucursalController(ListarSucursalesUseCase listarSucursalesUseCase) {
    this.listarSucursalesUseCase = listarSucursalesUseCase;
  }

  /**
   * Cualquier usuario autenticado del tenant puede listar sus sucursales (elegir dónde reservar,
   * ver la agenda).
   */
  @GetMapping("/api/v1/sucursales")
  public List<SucursalResponse> listar() {
    return listarSucursalesUseCase.execute(null).stream().map(SucursalResponse::from).toList();
  }
}
