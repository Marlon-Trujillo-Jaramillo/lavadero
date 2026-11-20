package com.lavadero.scheduling.domain.repository;

import com.lavadero.scheduling.domain.model.crm.ClienteResumen;
import com.lavadero.scheduling.domain.model.crm.FiltroClientes;
import com.lavadero.scheduling.domain.model.crm.PaginaClientes;
import com.lavadero.scheduling.domain.model.crm.VisitaCliente;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

/**
 * Consultas de solo lectura del CRM. No guarda nada: los datos salen de {@code reserva}, {@code
 * usuario} y {@code vehiculo}. RLS acota todo al tenant actual; {@code sucursalId} (opcional) acota
 * además a una sucursal.
 */
public interface ClienteCrmRepository {

  PaginaClientes buscar(FiltroClientes filtro);

  /** Vacío si el cliente no es del tenant o, con {@code sucursalId}, nunca reservó ahí. */
  Optional<ClienteResumen> resumen(UUID clienteId, UUID sucursalId, Instant ahora);

  /** Reservas más recientes primero (cualquier estado). */
  List<VisitaCliente> historial(UUID clienteId, UUID sucursalId, int limite);

  /** Nombre del servicio que más ha completado, si completó alguno. */
  Optional<String> servicioFavorito(UUID clienteId, UUID sucursalId);
}
