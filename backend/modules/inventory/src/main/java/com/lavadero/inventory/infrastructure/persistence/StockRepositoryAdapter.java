package com.lavadero.inventory.infrastructure.persistence;

import com.lavadero.inventory.domain.model.StockInsumo;
import com.lavadero.inventory.domain.repository.StockRepository;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
class StockRepositoryAdapter implements StockRepository {

  private final NamedParameterJdbcTemplate jdbc;

  StockRepositoryAdapter(NamedParameterJdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public BigDecimal sumar(UUID tenantId, UUID insumoId, UUID sucursalId, BigDecimal delta) {
    return jdbc.queryForObject(
        "insert into stock_insumo (tenant_id, insumo_id, sucursal_id, cantidad)"
            + " values (:tenantId, :insumoId, :sucursalId, :delta)"
            + " on conflict (insumo_id, sucursal_id)"
            + " do update set cantidad = stock_insumo.cantidad + excluded.cantidad"
            + " returning cantidad",
        clave(tenantId, insumoId, sucursalId).addValue("delta", delta),
        BigDecimal.class);
  }

  @Override
  public BigDecimal fijar(UUID tenantId, UUID insumoId, UUID sucursalId, BigDecimal cantidad) {
    MapSqlParameterSource params = clave(tenantId, insumoId, sucursalId);
    // Asegura que la fila exista y la bloquea hasta el fin de la transacción.
    jdbc.update(
        "insert into stock_insumo (tenant_id, insumo_id, sucursal_id)"
            + " values (:tenantId, :insumoId, :sucursalId) on conflict do nothing",
        params);
    BigDecimal anterior =
        jdbc.queryForObject(
            "select cantidad from stock_insumo"
                + " where insumo_id = :insumoId and sucursal_id = :sucursalId for update",
            params,
            BigDecimal.class);
    jdbc.update(
        "update stock_insumo set cantidad = :cantidad"
            + " where insumo_id = :insumoId and sucursal_id = :sucursalId",
        params.addValue("cantidad", cantidad));
    return anterior;
  }

  @Override
  public void fijarMinimo(UUID tenantId, UUID insumoId, UUID sucursalId, BigDecimal minimo) {
    jdbc.update(
        "insert into stock_insumo (tenant_id, insumo_id, sucursal_id, minimo)"
            + " values (:tenantId, :insumoId, :sucursalId, :minimo)"
            + " on conflict (insumo_id, sucursal_id) do update set minimo = excluded.minimo",
        clave(tenantId, insumoId, sucursalId).addValue("minimo", minimo));
  }

  @Override
  public List<StockInsumo> deSucursal(UUID sucursalId) {
    return jdbc.query(
        "select insumo_id, sucursal_id, cantidad, minimo from stock_insumo"
            + " where sucursal_id = :sucursalId",
        new MapSqlParameterSource("sucursalId", sucursalId),
        (rs, n) ->
            new StockInsumo(
                rs.getObject("insumo_id", UUID.class),
                rs.getObject("sucursal_id", UUID.class),
                rs.getBigDecimal("cantidad"),
                rs.getBigDecimal("minimo")));
  }

  private static MapSqlParameterSource clave(UUID tenantId, UUID insumoId, UUID sucursalId) {
    return new MapSqlParameterSource()
        .addValue("tenantId", tenantId)
        .addValue("insumoId", insumoId)
        .addValue("sucursalId", sucursalId);
  }
}
