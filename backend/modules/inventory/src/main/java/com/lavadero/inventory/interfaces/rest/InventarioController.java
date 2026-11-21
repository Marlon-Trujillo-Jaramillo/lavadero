package com.lavadero.inventory.interfaces.rest;

import com.lavadero.inventory.application.command.CambioStockCommand;
import com.lavadero.inventory.application.command.CrearInsumoCommand;
import com.lavadero.inventory.application.command.DefinirRecetaCommand;
import com.lavadero.inventory.application.command.InventarioQuery;
import com.lavadero.inventory.application.dto.CostoServicioDto;
import com.lavadero.inventory.application.dto.InsumoConStockDto;
import com.lavadero.inventory.application.dto.MovimientoDto;
import com.lavadero.inventory.application.usecase.AjustarStockUseCase;
import com.lavadero.inventory.application.usecase.CrearInsumoUseCase;
import com.lavadero.inventory.application.usecase.DefinirRecetaUseCase;
import com.lavadero.inventory.application.usecase.FijarMinimoUseCase;
import com.lavadero.inventory.application.usecase.ListarCostosPorServicioUseCase;
import com.lavadero.inventory.application.usecase.ListarInventarioUseCase;
import com.lavadero.inventory.application.usecase.ListarMovimientosUseCase;
import com.lavadero.inventory.application.usecase.RegistrarEntradaUseCase;
import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.model.UnidadMedida;
import com.lavadero.inventory.interfaces.rest.dto.CambioStockRequest;
import com.lavadero.inventory.interfaces.rest.dto.CrearInsumoRequest;
import com.lavadero.inventory.interfaces.rest.dto.DefinirRecetaRequest;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.PrincipalAutenticado;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Inventario de insumos — ver docs/specs/012-inventario.md. El dueño crea insumos y define recetas;
 * los dos admins registran entradas, conteos y mínimos (el de sucursal, solo en la suya).
 */
@RestController
public class InventarioController {

  private final CrearInsumoUseCase crearInsumo;
  private final ListarInventarioUseCase listarInventario;
  private final RegistrarEntradaUseCase registrarEntrada;
  private final AjustarStockUseCase ajustarStock;
  private final FijarMinimoUseCase fijarMinimo;
  private final ListarMovimientosUseCase listarMovimientos;
  private final DefinirRecetaUseCase definirReceta;
  private final ListarCostosPorServicioUseCase listarCostos;

  @SuppressWarnings("java:S107") // un caso de uso por operación (CLAUDE.md)
  public InventarioController(
      CrearInsumoUseCase crearInsumo,
      ListarInventarioUseCase listarInventario,
      RegistrarEntradaUseCase registrarEntrada,
      AjustarStockUseCase ajustarStock,
      FijarMinimoUseCase fijarMinimo,
      ListarMovimientosUseCase listarMovimientos,
      DefinirRecetaUseCase definirReceta,
      ListarCostosPorServicioUseCase listarCostos) {
    this.crearInsumo = crearInsumo;
    this.listarInventario = listarInventario;
    this.registrarEntrada = registrarEntrada;
    this.ajustarStock = ajustarStock;
    this.fijarMinimo = fijarMinimo;
    this.listarMovimientos = listarMovimientos;
    this.definirReceta = definirReceta;
    this.listarCostos = listarCostos;
  }

  @GetMapping("/api/v1/inventario/insumos")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<InsumoConStockDto> listar(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @RequestParam(required = false) UUID sucursalId) {
    return listarInventario.execute(
        new InventarioQuery(sucursalId, null, AlcanceSucursal.de(principal)));
  }

  @PostMapping("/api/v1/inventario/insumos")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ResponseEntity<Map<String, UUID>> crear(@Valid @RequestBody CrearInsumoRequest r) {
    UUID id =
        crearInsumo.execute(
            new CrearInsumoCommand(r.nombre(), unidad(r.unidad()), r.costoUnitario()));
    return ResponseEntity.created(URI.create("/api/v1/inventario/insumos/" + id))
        .body(Map.of("id", id));
  }

  @PostMapping("/api/v1/inventario/insumos/{id}/entradas")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public MovimientoDto entrada(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @PathVariable UUID id,
      @Valid @RequestBody CambioStockRequest r) {
    return registrarEntrada.execute(comando(principal, id, r));
  }

  @PostMapping("/api/v1/inventario/insumos/{id}/ajustes")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public MovimientoDto ajuste(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @PathVariable UUID id,
      @Valid @RequestBody CambioStockRequest r) {
    return ajustarStock.execute(comando(principal, id, r));
  }

  @PutMapping("/api/v1/inventario/insumos/{id}/minimo")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ResponseEntity<Void> minimo(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @PathVariable UUID id,
      @Valid @RequestBody CambioStockRequest r) {
    fijarMinimo.execute(comando(principal, id, r));
    return ResponseEntity.noContent().build();
  }

  @GetMapping("/api/v1/inventario/insumos/{id}/movimientos")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<MovimientoDto> movimientos(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @PathVariable UUID id,
      @RequestParam(required = false) UUID sucursalId) {
    return listarMovimientos.execute(
        new InventarioQuery(sucursalId, id, AlcanceSucursal.de(principal)));
  }

  @GetMapping("/api/v1/inventario/costos")
  @PreAuthorize("hasAnyRole('ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<CostoServicioDto> costos() {
    return listarCostos.execute();
  }

  @PutMapping("/api/v1/inventario/recetas/{servicioId}")
  @PreAuthorize("hasRole('ADMIN_TENANT')")
  public ResponseEntity<Void> receta(
      @PathVariable UUID servicioId, @Valid @RequestBody DefinirRecetaRequest r) {
    definirReceta.execute(
        new DefinirRecetaCommand(
            servicioId,
            r.lineas().stream().map(l -> new LineaReceta(l.insumoId(), l.cantidad())).toList()));
    return ResponseEntity.noContent().build();
  }

  private static CambioStockCommand comando(
      PrincipalAutenticado principal, UUID insumoId, CambioStockRequest r) {
    return new CambioStockCommand(
        insumoId, r.sucursalId(), r.cantidad(), r.nota(), AlcanceSucursal.de(principal));
  }

  private static UnidadMedida unidad(String valor) {
    try {
      return UnidadMedida.valueOf(valor.trim().toUpperCase(Locale.ROOT));
    } catch (IllegalArgumentException e) {
      throw new ValidationException("'unidad' debe ser uno de: ML, G, UNIDAD");
    }
  }
}
