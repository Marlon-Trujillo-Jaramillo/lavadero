package com.lavadero.scheduling.infrastructure.persistence;

import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_INTERVALO_FRECUENTE;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_MINIMOS_RIESGO;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_RIESGO_UNA_VISITA;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_VENTANA_NUEVO;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.VISITAS_FRECUENTE;

import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.crm.ClienteResumen;
import com.lavadero.scheduling.domain.model.crm.FiltroClientes;
import com.lavadero.scheduling.domain.model.crm.OrdenClientes;
import com.lavadero.scheduling.domain.model.crm.PaginaClientes;
import com.lavadero.scheduling.domain.model.crm.SegmentoCliente;
import com.lavadero.scheduling.domain.model.crm.VisitaCliente;
import com.lavadero.scheduling.domain.repository.ClienteCrmRepository;
import com.lavadero.shared.domain.Money;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.EnumMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * El CRM es un modelo de lectura sobre tablas de tres módulos (reserva, usuario, vehiculo), así que
 * va en SQL directo con {@link NamedParameterJdbcTemplate} en vez de entidades JPA: una sola
 * consulta agrega por cliente, calcula el segmento y pagina en Postgres. Corre en la transacción
 * del caso de uso, así que RLS aplica igual que con JPA.
 *
 * <p>El SQL se arma con fragmentos fijos (nunca con texto del usuario): solo cambian el join según
 * haya sucursal, el filtro de búsqueda y el ORDER BY de una lista cerrada. Los valores van siempre
 * como parámetros.
 */
@Repository
class ClienteCrmRepositoryAdapter implements ClienteCrmRepository {

  private final NamedParameterJdbcTemplate jdbc;

  ClienteCrmRepositoryAdapter(NamedParameterJdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public PaginaClientes buscar(FiltroClientes filtro) {
    MapSqlParameterSource params = parametrosBase(filtro.sucursalId(), filtro.ahora());
    String busqueda = "";
    if (filtro.busqueda() != null && !filtro.busqueda().isBlank()) {
      busqueda = " and (c.nombre ilike :q or c.email ilike :q)";
      params.addValue("q", "%" + escaparLike(filtro.busqueda().trim()) + "%");
    }
    String cte = cteClientes(filtro.sucursalId(), "");

    Map<SegmentoCliente, Long> porSegmento = new EnumMap<>(SegmentoCliente.class);
    for (SegmentoCliente segmento : SegmentoCliente.values()) {
      porSegmento.put(segmento, 0L);
    }
    jdbc.query(
        cte
            + "select c.segmento, count(*) as cantidad from clientes c where true"
            + busqueda
            + " group by c.segmento",
        params,
        rs -> {
          porSegmento.put(
              SegmentoCliente.valueOf(rs.getString("segmento")), rs.getLong("cantidad"));
        });

    String filtroSegmento = "";
    if (filtro.segmento() != null) {
      filtroSegmento = " and c.segmento = :segmento";
      params.addValue("segmento", filtro.segmento().name());
    }
    params.addValue("limite", filtro.tamano());
    params.addValue("desplazamiento", (long) filtro.pagina() * filtro.tamano());
    List<ClienteResumen> clientes =
        jdbc.query(
            cte
                + "select c.* from clientes c where true"
                + busqueda
                + filtroSegmento
                + " order by "
                + ordenSql(filtro.orden())
                + " limit :limite offset :desplazamiento",
            params,
            (rs, i) -> mapearResumen(rs));

    long total =
        filtro.segmento() == null
            ? porSegmento.values().stream().mapToLong(Long::longValue).sum()
            : porSegmento.get(filtro.segmento());
    return new PaginaClientes(clientes, total, porSegmento);
  }

  @Override
  public Optional<ClienteResumen> resumen(UUID clienteId, UUID sucursalId, Instant ahora) {
    MapSqlParameterSource params =
        parametrosBase(sucursalId, ahora).addValue("clienteId", clienteId);
    return jdbc
        .query(
            cteClientes(sucursalId, " and u.id = :clienteId") + "select c.* from clientes c",
            params,
            (rs, i) -> mapearResumen(rs))
        .stream()
        .findFirst();
  }

  @Override
  public List<VisitaCliente> historial(UUID clienteId, UUID sucursalId, int limite) {
    MapSqlParameterSource params =
        new MapSqlParameterSource().addValue("clienteId", clienteId).addValue("limite", limite);
    return jdbc.query(
        "select r.id, r.fecha_hora_inicio, s.nombre as servicio, su.nombre as sucursal, r.estado,"
            + " r.precio, r.moneda, r.vehiculo_placa"
            + " from reserva r"
            + " join servicio s on s.id = r.servicio_id"
            + " join sucursal su on su.id = r.sucursal_id"
            + " where r.cliente_id = :clienteId"
            + filtroSucursal(sucursalId, params)
            + " order by r.fecha_hora_inicio desc limit :limite",
        params,
        (rs, i) ->
            new VisitaCliente(
                rs.getObject("id", UUID.class),
                instante(rs, "fecha_hora_inicio"),
                rs.getString("servicio"),
                rs.getString("sucursal"),
                ReservaEstado.valueOf(rs.getString("estado")),
                Money.de(rs.getBigDecimal("precio"), rs.getString("moneda")),
                rs.getString("vehiculo_placa")));
  }

  @Override
  public Optional<String> servicioFavorito(UUID clienteId, UUID sucursalId) {
    MapSqlParameterSource params = new MapSqlParameterSource().addValue("clienteId", clienteId);
    return jdbc
        .queryForList(
            "select s.nombre from reserva r join servicio s on s.id = r.servicio_id"
                + " where r.cliente_id = :clienteId and r.estado = 'COMPLETADA'"
                + filtroSucursal(sucursalId, params)
                + " group by s.id, s.nombre"
                + " order by count(*) desc, max(r.fecha_hora_inicio) desc limit 1",
            params,
            String.class)
        .stream()
        .findFirst();
  }

  /**
   * Agrega las reservas por cliente y calcula el segmento (regla documentada en {@link
   * SegmentoCliente}). Sin sucursal, aparecen todos los clientes del tenant, aunque no hayan
   * reservado; con sucursal, solo los que reservaron en ella (inner join) y sus cifras cuentan solo
   * esa sucursal. El ritmo de un cliente es {@code (ultima - primera) / (visitas - 1)}.
   */
  private static String cteClientes(UUID sucursalId, String filtroUsuario) {
    String whereReserva = sucursalId == null ? "" : " where r.sucursal_id = :sucursalId";
    String joinStats = sucursalId == null ? "left join" : "join";
    return "with stats as ("
        + " select r.cliente_id,"
        + "  count(*) filter (where r.estado = 'COMPLETADA') as visitas,"
        + "  sum(r.precio) filter (where r.estado = 'COMPLETADA') as gasto,"
        + "  min(r.moneda) as moneda,"
        + "  min(r.fecha_hora_inicio) filter (where r.estado = 'COMPLETADA') as primera,"
        + "  max(r.fecha_hora_inicio) filter (where r.estado = 'COMPLETADA') as ultima,"
        + "  min(r.fecha_hora_inicio) filter"
        + "   (where r.estado = 'PENDIENTE' and r.fecha_hora_inicio >= :ahora) as proxima"
        + " from reserva r"
        + whereReserva
        + " group by r.cliente_id"
        + "), vehiculos as ("
        + " select v.cliente_id, count(*) as cantidad from vehiculo v where v.activo"
        + " group by v.cliente_id"
        + "), base as ("
        + " select u.id, u.nombre, u.email,"
        + "  coalesce(s.visitas, 0) as visitas, coalesce(s.gasto, 0) as gasto,"
        + "  coalesce(s.moneda, 'COP') as moneda, s.primera, s.ultima, s.proxima,"
        + "  coalesce(v.cantidad, 0) as vehiculos"
        + " from usuario u "
        + joinStats
        + " stats s on s.cliente_id = u.id"
        + " left join vehiculos v on v.cliente_id = u.id"
        + " where exists (select 1 from usuario_rol ur"
        + "  where ur.usuario_id = u.id and ur.rol = 'CLIENTE')"
        + filtroUsuario
        + "), clientes as ("
        + " select b.*, case"
        + "  when b.visitas = 0 then 'SIN_VISITAS'"
        + "  when b.proxima is null and b.ultima < :ahora - case"
        + "    when b.visitas = 1 then make_interval(days => :diasRiesgoUnaVisita)"
        + "    else greatest(make_interval(days => :diasMinimosRiesgo),"
        + "     2 * (b.ultima - b.primera) / (b.visitas - 1)) end then 'EN_RIESGO'"
        + "  when b.primera >= :ahora - make_interval(days => :diasVentanaNuevo) then 'NUEVO'"
        + "  when b.visitas >= :visitasFrecuente and (b.ultima - b.primera) / (b.visitas - 1)"
        + "   <= make_interval(days => :diasIntervaloFrecuente) then 'FRECUENTE'"
        + "  else 'OCASIONAL' end as segmento"
        + " from base b"
        + ") ";
  }

  private static MapSqlParameterSource parametrosBase(UUID sucursalId, Instant ahora) {
    MapSqlParameterSource params =
        new MapSqlParameterSource()
            .addValue("ahora", OffsetDateTime.ofInstant(ahora, ZoneOffset.UTC))
            .addValue("diasRiesgoUnaVisita", DIAS_RIESGO_UNA_VISITA)
            .addValue("diasMinimosRiesgo", DIAS_MINIMOS_RIESGO)
            .addValue("diasVentanaNuevo", DIAS_VENTANA_NUEVO)
            .addValue("visitasFrecuente", VISITAS_FRECUENTE)
            .addValue("diasIntervaloFrecuente", DIAS_INTERVALO_FRECUENTE);
    if (sucursalId != null) {
      params.addValue("sucursalId", sucursalId);
    }
    return params;
  }

  private static String filtroSucursal(UUID sucursalId, MapSqlParameterSource params) {
    if (sucursalId == null) {
      return "";
    }
    params.addValue("sucursalId", sucursalId);
    return " and r.sucursal_id = :sucursalId";
  }

  private static String ordenSql(OrdenClientes orden) {
    return switch (orden) {
      case ULTIMA_VISITA -> "c.ultima desc nulls last, lower(c.nombre), c.id";
      case GASTO -> "c.gasto desc, lower(c.nombre), c.id";
      case VISITAS -> "c.visitas desc, lower(c.nombre), c.id";
      case NOMBRE -> "lower(c.nombre), c.id";
    };
  }

  /** {@code %} y {@code _} del texto buscado son literales, no comodines. */
  static String escaparLike(String texto) {
    return texto.replace("\\", "\\\\").replace("%", "\\%").replace("_", "\\_");
  }

  private static ClienteResumen mapearResumen(ResultSet rs) throws SQLException {
    return new ClienteResumen(
        rs.getObject("id", UUID.class),
        rs.getString("nombre"),
        rs.getString("email"),
        rs.getInt("visitas"),
        Money.de(rs.getBigDecimal("gasto"), rs.getString("moneda")),
        instante(rs, "primera"),
        instante(rs, "ultima"),
        instante(rs, "proxima"),
        rs.getInt("vehiculos"),
        SegmentoCliente.valueOf(rs.getString("segmento")));
  }

  private static Instant instante(ResultSet rs, String columna) throws SQLException {
    OffsetDateTime valor = rs.getObject(columna, OffsetDateTime.class);
    return valor == null ? null : valor.toInstant();
  }
}
