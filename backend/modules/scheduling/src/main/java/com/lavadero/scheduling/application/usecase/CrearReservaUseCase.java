package com.lavadero.scheduling.application.usecase;

import com.lavadero.catalog.application.dto.ServicioDto;
import com.lavadero.catalog.application.usecase.ObtenerServicioPorIdUseCase;
import com.lavadero.scheduling.application.command.CrearReservaCommand;
import com.lavadero.scheduling.application.dto.ReservaDto;
import com.lavadero.scheduling.domain.model.PromocionAplicada;
import com.lavadero.scheduling.domain.model.Reserva;
import com.lavadero.scheduling.domain.model.Vehiculo;
import com.lavadero.scheduling.domain.model.VehiculoReservado;
import com.lavadero.scheduling.domain.model.promocion.PrecioCotizado;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import com.lavadero.scheduling.domain.repository.ReservaRepository;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.scheduling.domain.service.DisponibilidadService;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.application.exception.ValidationException;
import com.lavadero.shared.domain.Money;
import com.lavadero.shared.security.TenantContext;
import com.lavadero.tenant.application.dto.SucursalDto;
import com.lavadero.tenant.application.usecase.ObtenerSucursalPorIdUseCase;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Crea una reserva del tenant actual, validando disponibilidad (capacidad de la sucursal en ese
 * horario, ver {@link DisponibilidadService}) y congelando precio/duración del servicio al momento
 * de reservar. Resuelve servicio/sucursal a través de la capa `application` de los módulos
 * `catalog`/`tenant-management` (no de sus repositorios de dominio directamente) — mismo patrón que
 * usa `identity-access` para llamar a `tenant-management` (ver `LoginUseCase`).
 */
@Service
public class CrearReservaUseCase implements UseCase<CrearReservaCommand, ReservaDto> {

  private final ReservaRepository reservaRepository;
  private final ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase;
  private final ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase;
  private final VehiculoRepository vehiculoRepository;
  private final PromocionRepository promocionRepository;
  private final ResolvedorPromociones resolvedorPromociones;

  public CrearReservaUseCase(
      ReservaRepository reservaRepository,
      ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase,
      ObtenerSucursalPorIdUseCase obtenerSucursalPorIdUseCase,
      VehiculoRepository vehiculoRepository,
      PromocionRepository promocionRepository,
      ResolvedorPromociones resolvedorPromociones) {
    this.reservaRepository = reservaRepository;
    this.obtenerServicioPorIdUseCase = obtenerServicioPorIdUseCase;
    this.obtenerSucursalPorIdUseCase = obtenerSucursalPorIdUseCase;
    this.vehiculoRepository = vehiculoRepository;
    this.promocionRepository = promocionRepository;
    this.resolvedorPromociones = resolvedorPromociones;
  }

  @Override
  @Transactional
  public ReservaDto execute(CrearReservaCommand input) {
    ServicioDto servicio = obtenerServicioPorIdUseCase.execute(input.servicioId());
    if (!servicio.activo()) {
      throw new ValidationException("El servicio '%s' no está activo".formatted(servicio.nombre()));
    }

    SucursalDto sucursal = obtenerSucursalPorIdUseCase.execute(input.sucursalId());
    VehiculoReservado vehiculo = resolverVehiculo(input);

    Instant inicio = input.fechaHoraInicio();
    Instant fin = inicio.plus(Duration.ofMinutes(servicio.duracionEstimadaMinutos()));

    reservaRepository.bloquearAgendaDeSucursal(input.sucursalId());
    List<Reserva> activasEnRango =
        reservaRepository.findActivasPorSucursalYRango(input.sucursalId(), inicio, fin);
    boolean hayCupo =
        DisponibilidadService.hayCupo(sucursal.capacidadSimultanea(), activasEnRango, inicio, fin);
    if (!hayCupo) {
      throw new ValidationException("No hay cupo disponible en esa sucursal para ese horario");
    }

    Money precioLista = Money.de(servicio.precio(), servicio.moneda());
    PrecioCotizado precio = resolvedorPromociones.cotizar(precioLista, inicio, input.codigoCupon());
    PromocionAplicada promocion = reservarUsoDePromocion(precio);

    Reserva reserva =
        Reserva.nueva(
            TenantContext.requerido(),
            input.sucursalId(),
            input.servicioId(),
            input.clienteId(),
            inicio,
            servicio.duracionEstimadaMinutos(),
            precio.precioFinal(),
            vehiculo,
            promocion);

    return ReservaMapper.toDto(reservaRepository.save(reserva));
  }

  /**
   * Gasta un uso de la promoción elegida. Si otra reserva se llevó el último cupo entre la
   * cotización y este momento, el UPDATE condicional no cambia nada y la reserva no se crea.
   */
  private PromocionAplicada reservarUsoDePromocion(PrecioCotizado precio) {
    return precio
        .getPromocion()
        .map(
            p -> {
              if (!promocionRepository.reservarUso(p.getId())) {
                throw new ValidationException(
                    "La promoción '%s' se acaba de agotar".formatted(p.getNombre()));
              }
              return new PromocionAplicada(p.getId(), precio.precioLista());
            })
        .orElse(null);
  }

  /**
   * El vehículo es opcional. Si viene, tiene que ser del mismo cliente y estar activo: RLS ya lo
   * acota al tenant, pero dentro del tenant un cliente no puede reservar con el carro de otro. Un
   * vehículo ajeno responde 404 (no confirma que ese id exista).
   */
  private VehiculoReservado resolverVehiculo(CrearReservaCommand input) {
    if (input.vehiculoId() == null) {
      return null;
    }
    return vehiculoRepository
        .findById(input.vehiculoId())
        .filter(v -> v.perteneceA(input.clienteId()) && v.isActivo())
        .map(Vehiculo::paraReserva)
        .orElseThrow(() -> NotFoundException.de("Vehículo", input.vehiculoId()));
  }
}
