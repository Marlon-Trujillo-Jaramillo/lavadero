package com.lavadero.scheduling.infrastructure.persistence;

import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_INTERVALO_FRECUENTE;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_MINIMOS_RIESGO;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_RIESGO_UNA_VISITA;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.DIAS_VENTANA_NUEVO;
import static com.lavadero.scheduling.domain.model.crm.SegmentoCliente.VISITAS_FRECUENTE;

import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.crm.ClienteResumen;
import com.lavadero.scheduling.domain.model.crm.FiltroClientes;
import com.lavadero.scheduling.domain.model.crm.PaginaClientes;
import com.lavadero.scheduling.domain.model.crm.SegmentoCliente;
import com.lavadero.scheduling.domain.model.crm.VisitaCliente;
import com.lavadero.scheduling.domain.repository.ClienteCrmRepository;
import com.lavadero.shared.domain.Money;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
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
 * <p>Todo el SQL es constante: los filtros opcionales (sucursal, cliente, búsqueda, segmento) y el
 * orden son parámetros ({@code cast(:x as uuid) is null or ...}), nunca texto concatenado. Así no
 * hay forma de que un valor del usuario termine dentro de la sentencia.
 */
@Repository
class ClienteCrmRepositoryAdapter implements ClienteCrmRepository {

  /**
   * Agrega las reservas por cliente y calcula el segmento (regla documentada en {@link
   * SegmentoCliente}). Sin sucursal aparecen todos los clientes del tenant, aunque no hayan
   * reservado; con sucursal, solo los que reservaron en ella y sus cifras cuentan solo esa
   * sucursal. El ritmo de un cliente es {@code (ultima - primera) / (visitas - 1)}.
   */
  private static final String CTE_CLIENTES =
      """
      with stats as (
        select r.cliente_id,
          count(*) filter (where r.estado = 'COMPLETADA') as visitas,
          sum(r.precio) filter (where r.estado = 'COMPLETADA') as gasto,
          min(r.moneda) as moneda,
          min(r.fecha_hora_inicio) filter (where r.estado = 'COMPLETADA') as primera,
          max(r.fecha_hora_inicio) filter (where r.estado = 'COMPLETADA') as ultima,
          min(r.fecha_hora_inicio) filter
            (where r.estado = 'PENDIENTE' and r.fecha_hora_inicio >= :ahora) as proxima
        from reserva r
        where (cast(:sucursalId as uuid) is null or r.sucursal_id = cast(:sucursalId as uuid))
        group by r.cliente_id
      ), vehiculos as (
        select v.cliente_id, count(*) as cantidad from vehiculo v where v.activo
        group by v.cliente_id
      ), base as (
        select u.id, u.nombre, u.email,
          coalesce(s.visitas, 0) as visitas, coalesce(s.gasto, 0) as gasto,
          coalesce(s.moneda, 'COP') as moneda, s.primera, s.ultima, s.proxima,
          coalesce(v.cantidad, 0) as vehiculos
        from usuario u
        left join stats s on s.cliente_id = u.id
        left join vehiculos v on v.cliente_id = u.id
        where exists (select 1 from usuario_rol ur
            where ur.usuario_id = u.id and ur.rol = 'CLIENTE')
          and (cast(:sucursalId as uuid) is null or s.cliente_id is not null)
          and (cast(:clienteId as uuid) is null or u.id = cast(:clienteId as uuid))
      ), clientes as (
        select b.*, case
          when b.visitas = 0 then 'SIN_VISITAS'
          when b.proxima is null and b.ultima < :ahora - case
            when b.visitas = 1 then make_interval(days => :diasRiesgoUnaVisita)
            else greatest(make_interval(days => :diasMinimosRiesgo),
              2 * (b.ultima - b.primera) / (b.visitas - 1)) end then 'EN_RIESGO'
          when b.primera >= :ahora - make_interval(days => :diasVentanaNuevo) then 'NUEVO'
          when b.visitas >= :visitasFrecuente and (b.ultima - b.primera) / (b.visitas - 1)
            <= make_interval(days => :diasIntervaloFrecuente) then 'FRECUENTE'
          else 'OCASIONAL' end as segmento
        from base b
      ), filtrados as (
        select c.* from clientes c
        where (cast(:q as text) is null or c.nombre ilike :q or c.email ilike :q)
      )
      """;

  private static final String SQL_CONTEO_POR_SEGMENTO =
      CTE_CLIENTES + "select f.segmento, count(*) as cantidad from filtrados f group by f.segmento";

  /** El orden elegido activa una sola de las tres primeras claves; las demás quedan en null. */
  private static final String SQL_PAGINA =
      CTE_CLIENTES
          + """
          select f.* from filtrados f
          where (cast(:segmento as text) is null or f.segmento = :segmento)
          order by
            case when :orden = 'ULTIMA_VISITA' then f.ultima end desc nulls last,
            case when :orden = 'GASTO' then f.gasto end desc,
            case when :orden = 'VISITAS' then f.visitas end desc,
            lower(f.nombre), f.id
          limit :limite offset :desplazamiento
          """;

  private static final String SQL_RESUMEN = CTE_CLIENTES + "select f.* from filtrados f";

  private static final String SQL_HISTORIAL =
      """
      select r.id, r.fecha_hora_inicio, s.nombre as servicio, su.nombre as sucursal, r.estado,
        r.precio, r.moneda, r.vehiculo_placa
      from reserva r
      join servicio s on s.id = r.servicio_id
      join sucursal su on su.id = r.sucursal_id
      where r.cliente_id = :clienteId
        and (cast(:sucursalId as uuid) is null or r.sucursal_id = cast(:sucursalId as uuid))
      order by r.fecha_hora_inicio desc
      limit :limite
      """;

  private static final String SQL_SERVICIO_FAVORITO =
      """
      select s.nombre from reserva r join servicio s on s.id = r.servicio_id
      where r.cliente_id = :clienteId and r.estado = 'COMPLETADA'
        and (cast(:sucursalId as uuid) is null or r.sucursal_id = cast(:sucursalId as uuid))
      group by s.id, s.nombre
      order by count(*) desc, max(r.fecha_hora_inicio) desc
      limit 1
      """;

  private final NamedParameterJdbcTemplate jdbc;

  ClienteCrmRepositoryAdapter(NamedParameterJdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public PaginaClientes buscar(FiltroClientes filtro) {
    String busqueda =
        filtro.busqueda() == null || filtro.busqueda().isBlank()
            ? null
            : "%" + escaparLike(filtro.busqueda().trim()) + "%";
    MapSqlParameterSource params =
        parametrosCte(filtro.sucursalId(), null, filtro.ahora())
            .addValue("q", busqueda, Types.VARCHAR);

    Map<SegmentoCliente, Long> porSegmento = new EnumMap<>(SegmentoCliente.class);
    for (SegmentoCliente segmento : SegmentoCliente.values()) {
      porSegmento.put(segmento, 0L);
    }
    jdbc.query(
        SQL_CONTEO_POR_SEGMENTO,
        params,
        rs -> {
          porSegmento.put(
              SegmentoCliente.valueOf(rs.getString("segmento")), rs.getLong("cantidad"));
        });

    params
        .addValue(
            "segmento", filtro.segmento() == null ? null : filtro.segmento().name(), Types.VARCHAR)
        .addValue("orden", filtro.orden().name(), Types.VARCHAR)
        .addValue("limite", filtro.tamano())
        .addValue("desplazamiento", (long) filtro.pagina() * filtro.tamano());
    List<ClienteResumen> clientes = jdbc.query(SQL_PAGINA, params, (rs, i) -> mapearResumen(rs));

    long total =
        filtro.segmento() == null
            ? porSegmento.values().stream().mapToLong(Long::longValue).sum()
            : porSegmento.get(filtro.segmento());
    return new PaginaClientes(clientes, total, porSegmento);
  }

  @Override
  public Optional<ClienteResumen> resumen(UUID clienteId, UUID sucursalId, Instant ahora) {
    MapSqlParameterSource params =
        parametrosCte(sucursalId, clienteId, ahora).addValue("q", null, Types.VARCHAR);
    return jdbc.query(SQL_RESUMEN, params, (rs, i) -> mapearResumen(rs)).stream().findFirst();
  }

  @Override
  public List<VisitaCliente> historial(UUID clienteId, UUID sucursalId, int limite) {
    MapSqlParameterSource params =
        new MapSqlParameterSource()
            .addValue("clienteId", clienteId)
            .addValue("sucursalId", sucursalId, Types.OTHER)
            .addValue("limite", limite);
    return jdbc.query(
        SQL_HISTORIAL,
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
    MapSqlParameterSource params =
        new MapSqlParameterSource()
            .addValue("clienteId", clienteId)
            .addValue("sucursalId", sucursalId, Types.OTHER);
    return jdbc.queryForList(SQL_SERVICIO_FAVORITO, params, String.class).stream().findFirst();
  }

  private static MapSqlParameterSource parametrosCte(
      UUID sucursalId, UUID clienteId, Instant ahora) {
    return new MapSqlParameterSource()
        .addValue("ahora", OffsetDateTime.ofInstant(ahora, ZoneOffset.UTC))
        .addValue("sucursalId", sucursalId, Types.OTHER)
        .addValue("clienteId", clienteId, Types.OTHER)
        .addValue("diasRiesgoUnaVisita", DIAS_RIESGO_UNA_VISITA)
        .addValue("diasMinimosRiesgo", DIAS_MINIMOS_RIESGO)
        .addValue("diasVentanaNuevo", DIAS_VENTANA_NUEVO)
        .addValue("visitasFrecuente", VISITAS_FRECUENTE)
        .addValue("diasIntervaloFrecuente", DIAS_INTERVALO_FRECUENTE);
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
