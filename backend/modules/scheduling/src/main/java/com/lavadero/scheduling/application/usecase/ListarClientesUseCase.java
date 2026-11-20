package com.lavadero.scheduling.application.usecase;

import com.lavadero.scheduling.application.command.ListarClientesQuery;
import com.lavadero.scheduling.application.dto.PaginaClientesDto;
import com.lavadero.scheduling.domain.model.crm.FiltroClientes;
import com.lavadero.scheduling.domain.model.crm.OrdenClientes;
import com.lavadero.scheduling.domain.model.crm.PaginaClientes;
import com.lavadero.scheduling.domain.repository.ClienteCrmRepository;
import com.lavadero.shared.application.UseCase;
import com.lavadero.shared.application.exception.ValidationException;
import java.time.Clock;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Lista paginada de clientes del CRM, con su segmento y el conteo por segmento. */
@Service
public class ListarClientesUseCase implements UseCase<ListarClientesQuery, PaginaClientesDto> {

  static final int TAMANO_MAXIMO = 100;
  static final int BUSQUEDA_MAXIMA = 100;

  private final ClienteCrmRepository clienteCrmRepository;
  private final Clock reloj;

  public ListarClientesUseCase(ClienteCrmRepository clienteCrmRepository, Clock reloj) {
    this.clienteCrmRepository = clienteCrmRepository;
    this.reloj = reloj;
  }

  @Override
  @Transactional(readOnly = true)
  public PaginaClientesDto execute(ListarClientesQuery input) {
    if (input.pagina() < 0) {
      throw new ValidationException("'pagina' no puede ser negativa");
    }
    if (input.tamano() < 1 || input.tamano() > TAMANO_MAXIMO) {
      throw new ValidationException("'tamano' debe estar entre 1 y " + TAMANO_MAXIMO);
    }
    if (input.busqueda() != null && input.busqueda().length() > BUSQUEDA_MAXIMA) {
      throw new ValidationException(
          "La búsqueda no puede superar " + BUSQUEDA_MAXIMA + " caracteres");
    }
    UUID sucursalId = input.alcance().resolverFiltro(input.sucursalId());
    OrdenClientes orden = input.orden() == null ? OrdenClientes.ULTIMA_VISITA : input.orden();

    PaginaClientes pagina =
        clienteCrmRepository.buscar(
            new FiltroClientes(
                input.segmento(),
                input.busqueda(),
                orden,
                sucursalId,
                input.pagina(),
                input.tamano(),
                reloj.instant()));

    Map<String, Long> porSegmento = new LinkedHashMap<>();
    pagina
        .porSegmento()
        .forEach((segmento, cantidad) -> porSegmento.put(segmento.name(), cantidad));
    return new PaginaClientesDto(
        pagina.clientes().stream().map(ClienteCrmMapper::toDto).toList(),
        pagina.total(),
        input.pagina(),
        input.tamano(),
        porSegmento);
  }
}
