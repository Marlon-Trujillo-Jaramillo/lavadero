package com.lavadero.inventory.infrastructure.persistence;

import com.lavadero.inventory.domain.model.MovimientoInventario;
import com.lavadero.inventory.domain.model.TipoMovimiento;
import com.lavadero.inventory.domain.repository.MovimientoRepository;
import java.sql.Timestamp;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
class MovimientoRepositoryAdapter implements MovimientoRepository {

  private final NamedParameterJdbcTemplate jdbc;

  MovimientoRepositoryAdapter(NamedParameterJdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public void registrar(UUID tenantId, MovimientoInventario m) {
    jdbc.update(
        "insert into movimiento_inventario (id, tenant_id, insumo_id, sucursal_id, tipo, cantidad,"
            + " saldo, reserva_id, nota, creado_en) values (:id, :tenantId, :insumoId, :sucursalId,"
            + " :tipo, :cantidad, :saldo, :reservaId, :nota, :creadoEn)",
        new MapSqlParameterSource()
            .addValue("id", m.id())
            .addValue("tenantId", tenantId)
            .addValue("insumoId", m.insumoId())
            .addValue("sucursalId", m.sucursalId())
            .addValue("tipo", m.tipo().name())
            .addValue("cantidad", m.cantidad())
            .addValue("saldo", m.saldo())
            .addValue("reservaId", m.reservaId(), java.sql.Types.OTHER)
            .addValue("nota", m.nota())
            .addValue("creadoEn", Timestamp.from(m.creadoEn())));
  }

  @Override
  public List<MovimientoInventario> recientes(UUID insumoId, UUID sucursalId, int limite) {
    return jdbc.query(
        "select id, insumo_id, sucursal_id, tipo, cantidad, saldo, reserva_id, nota, creado_en"
            + " from movimiento_inventario where insumo_id = :insumoId and sucursal_id = :sucursalId"
            + " order by creado_en desc limit :limite",
        new MapSqlParameterSource()
            .addValue("insumoId", insumoId)
            .addValue("sucursalId", sucursalId)
            .addValue("limite", limite),
        (rs, n) ->
            new MovimientoInventario(
                rs.getObject("id", UUID.class),
                rs.getObject("insumo_id", UUID.class),
                rs.getObject("sucursal_id", UUID.class),
                TipoMovimiento.valueOf(rs.getString("tipo")),
                rs.getBigDecimal("cantidad"),
                rs.getBigDecimal("saldo"),
                rs.getObject("reserva_id", UUID.class),
                rs.getString("nota"),
                rs.getTimestamp("creado_en").toInstant()));
  }

  @Override
  public boolean consumoRegistrado(UUID reservaId) {
    Boolean existe =
        jdbc.queryForObject(
            "select exists (select 1 from movimiento_inventario"
                + " where reserva_id = :reservaId and tipo = 'CONSUMO')",
            new MapSqlParameterSource("reservaId", reservaId),
            Boolean.class);
    return Boolean.TRUE.equals(existe);
  }
}
