package com.lavadero.scheduling.interfaces.rest;

import com.lavadero.scheduling.application.command.AgendaDiaQuery;
import com.lavadero.scheduling.application.command.CancelarReservaCommand;
import com.lavadero.scheduling.application.command.CrearReservaCommand;
import com.lavadero.scheduling.application.command.MisReservasQuery;
import com.lavadero.scheduling.application.command.ReservaStaffCommand;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.application.usecase.CancelarReservaUseCase;
import com.lavadero.scheduling.application.usecase.CompletarReservaUseCase;
import com.lavadero.scheduling.application.usecase.CrearReservaUseCase;
import com.lavadero.scheduling.application.usecase.IniciarReservaUseCase;
import com.lavadero.scheduling.application.usecase.ListarAgendaDelDiaUseCase;
import com.lavadero.scheduling.application.usecase.ListarMisReservasUseCase;
import com.lavadero.scheduling.interfaces.rest.dto.CrearReservaRequest;
import com.lavadero.scheduling.interfaces.rest.dto.ReservaResponse;
import com.lavadero.shared.security.AlcanceSucursal;
import com.lavadero.shared.security.PrincipalAutenticado;
import jakarta.validation.Valid;
import java.net.URI;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ReservaController {

  /** Sin {@code limite}, "mis reservas" devuelve como mucho esto (las más recientes). */
  static final int LIMITE_MIS_RESERVAS_DEFECTO = 50;

  static final int LIMITE_MIS_RESERVAS_MAXIMO = 200;

  private static final Set<String> ROLES_STAFF =
      Set.of("EMPLEADO", "ADMIN_SUCURSAL", "ADMIN_TENANT", "SUPER_ADMIN");

  private final CrearReservaUseCase crearReservaUseCase;
  private final IniciarReservaUseCase iniciarReservaUseCase;
  private final CompletarReservaUseCase completarReservaUseCase;
  private final CancelarReservaUseCase cancelarReservaUseCase;
  private final ListarAgendaDelDiaUseCase listarAgendaDelDiaUseCase;
  private final ListarMisReservasUseCase listarMisReservasUseCase;

  public ReservaController(
      CrearReservaUseCase crearReservaUseCase,
      IniciarReservaUseCase iniciarReservaUseCase,
      CompletarReservaUseCase completarReservaUseCase,
      CancelarReservaUseCase cancelarReservaUseCase,
      ListarAgendaDelDiaUseCase listarAgendaDelDiaUseCase,
      ListarMisReservasUseCase listarMisReservasUseCase) {
    this.crearReservaUseCase = crearReservaUseCase;
    this.iniciarReservaUseCase = iniciarReservaUseCase;
    this.completarReservaUseCase = completarReservaUseCase;
    this.cancelarReservaUseCase = cancelarReservaUseCase;
    this.listarAgendaDelDiaUseCase = listarAgendaDelDiaUseCase;
    this.listarMisReservasUseCase = listarMisReservasUseCase;
  }

  @PostMapping("/api/v1/agenda/reservas")
  @PreAuthorize("hasRole('CLIENTE')")
  public ResponseEntity<ReservaResponse> crear(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @Valid @RequestBody CrearReservaRequest request) {
    ReservaDto creada =
        crearReservaUseCase.execute(
            new CrearReservaCommand(
                principal.usuarioId(),
                request.sucursalId(),
                request.servicioId(),
                request.fechaHoraInicio()));
    return ResponseEntity.created(URI.create("/api/v1/agenda/reservas/" + creada.id()))
        .body(ReservaResponse.from(creada));
  }

  /**
   * Agenda de un día para una sucursal — vista de empleado/admin. {@code fecha} es un ISO date
   * (yyyy-MM-dd), interpretado en UTC. Un ADMIN_SUCURSAL solo puede pedir la suya (403 si no).
   */
  @GetMapping("/api/v1/agenda/reservas")
  @PreAuthorize("hasAnyRole('EMPLEADO','ADMIN_SUCURSAL','ADMIN_TENANT')")
  public List<ReservaResponse> agendaDelDia(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @RequestParam UUID sucursalId,
      @RequestParam LocalDate fecha) {
    var desde = FechasConsulta.inicioDelDia(fecha, "fecha");
    var hasta = FechasConsulta.finDelDia(fecha, "fecha");
    return listarAgendaDelDiaUseCase
        .execute(new AgendaDiaQuery(sucursalId, desde, hasta, AlcanceSucursal.de(principal)))
        .stream()
        .map(ReservaResponse::from)
        .toList();
  }

  /**
   * Reservas del cliente, más recientes primero. {@code limite} opcional (por defecto {@value
   * #LIMITE_MIS_RESERVAS_DEFECTO}, se acota a [1, {@value #LIMITE_MIS_RESERVAS_MAXIMO}]); {@code
   * desde} opcional (ISO date, UTC): solo reservas que inician ese día o después. La respuesta
   * sigue siendo una lista plana (compatible con los clientes existentes).
   */
  @GetMapping("/api/v1/agenda/reservas/mias")
  @PreAuthorize("hasRole('CLIENTE')")
  public List<ReservaResponse> misReservas(
      @AuthenticationPrincipal PrincipalAutenticado principal,
      @RequestParam(required = false) Integer limite,
      @RequestParam(required = false) LocalDate desde) {
    int limiteEfectivo =
        Math.clamp(
            limite == null ? LIMITE_MIS_RESERVAS_DEFECTO : limite, 1, LIMITE_MIS_RESERVAS_MAXIMO);
    var desdeInstant = desde == null ? null : FechasConsulta.inicioDelDia(desde, "desde");
    return listarMisReservasUseCase
        .execute(new MisReservasQuery(principal.usuarioId(), desdeInstant, limiteEfectivo))
        .stream()
        .map(ReservaResponse::from)
        .toList();
  }

  @PatchMapping("/api/v1/agenda/reservas/{id}/iniciar")
  @PreAuthorize("hasAnyRole('EMPLEADO','ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ReservaResponse iniciar(
      @PathVariable UUID id, @AuthenticationPrincipal PrincipalAutenticado principal) {
    return ReservaResponse.from(
        iniciarReservaUseCase.execute(new ReservaStaffCommand(id, AlcanceSucursal.de(principal))));
  }

  @PatchMapping("/api/v1/agenda/reservas/{id}/completar")
  @PreAuthorize("hasAnyRole('EMPLEADO','ADMIN_SUCURSAL','ADMIN_TENANT')")
  public ReservaResponse completar(
      @PathVariable UUID id, @AuthenticationPrincipal PrincipalAutenticado principal) {
    return ReservaResponse.from(
        completarReservaUseCase.execute(
            new ReservaStaffCommand(id, AlcanceSucursal.de(principal))));
  }

  /**
   * Cliente dueño o staff — la autorización fina (¿es realmente el dueño?) vive en el caso de uso.
   */
  @PatchMapping("/api/v1/agenda/reservas/{id}/cancelar")
  public ReservaResponse cancelar(
      @PathVariable UUID id, @AuthenticationPrincipal PrincipalAutenticado principal) {
    boolean esStaff = principal.roles().stream().anyMatch(ROLES_STAFF::contains);
    return ReservaResponse.from(
        cancelarReservaUseCase.execute(
            new CancelarReservaCommand(
                id, principal.usuarioId(), esStaff, AlcanceSucursal.de(principal))));
  }
}
