package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.FichaClienteQuery;
import com.lavadero.scheduling.application.dto.FichaClienteDto;
import com.lavadero.scheduling.domain.model.crm.ClienteResumen;
import com.lavadero.scheduling.domain.repository.ClienteCrmRepository;
import com.lavadero.scheduling.domain.repository.VehiculoRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.NotFoundException;
import java.time.Clock;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Ficha de un cliente: su resumen, servicio favorito, vehículos activos y las últimas reservas. Un
 * ADMIN_SUCURSAL solo ve clientes que han reservado en su sucursal, y solo esas reservas; para el
 * resto responde 404, igual que un cliente de otro lavadero.
 */
@Service
public class ObtenerFichaClienteUseCase implements UseCase<FichaClienteQuery, FichaClienteDto> {

  static final int HISTORIAL_MAXIMO = 20;

  private final ClienteCrmRepository clienteCrmRepository;
  private final VehiculoRepository vehiculoRepository;
  private final Clock reloj;

  public ObtenerFichaClienteUseCase(
      ClienteCrmRepository clienteCrmRepository,
      VehiculoRepository vehiculoRepository,
      Clock reloj) {
    this.clienteCrmRepository = clienteCrmRepository;
    this.vehiculoRepository = vehiculoRepository;
    this.reloj = reloj;
  }

  @Override
  @Transactional(readOnly = true)
  public FichaClienteDto execute(FichaClienteQuery input) {
    UUID sucursalId = input.alcance().resolverFiltro(input.sucursalId());
    ClienteResumen cliente =
        clienteCrmRepository
            .resumen(input.clienteId(), sucursalId, reloj.instant())
            .orElseThrow(() -> NotFoundException.de("Cliente", input.clienteId()));

    return new FichaClienteDto(
        ClienteCrmMapper.toDto(cliente),
        clienteCrmRepository.servicioFavorito(cliente.id(), sucursalId).orElse(null),
        vehiculoRepository.findActivosByClienteId(cliente.id()).stream()
            .map(VehiculoMapper::toDto)
            .toList(),
        clienteCrmRepository.historial(cliente.id(), sucursalId, HISTORIAL_MAXIMO).stream()
            .map(ClienteCrmMapper::toDto)
            .toList());
  }
}
