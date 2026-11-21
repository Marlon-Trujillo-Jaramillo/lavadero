package com.lavadero.inventory.infrastructure.persistence;

import com.lavadero.inventory.domain.model.LineaReceta;
import com.lavadero.inventory.domain.repository.RecetaRepository;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

@Repository
class RecetaRepositoryAdapter implements RecetaRepository {

  private final NamedParameterJdbcTemplate jdbc;

  RecetaRepositoryAdapter(NamedParameterJdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public List<LineaReceta> deServicio(UUID servicioId) {
    return jdbc.query(
        "select insumo_id, cantidad from consumo_servicio where servicio_id = :servicioId",
        new MapSqlParameterSource("servicioId", servicioId),
        (rs, n) ->
            new LineaReceta(rs.getObject("insumo_id", UUID.class), rs.getBigDecimal("cantidad")));
  }

  @Override
  public Map<UUID, List<LineaReceta>> todas() {
    Map<UUID, List<LineaReceta>> recetas = new LinkedHashMap<>();
    jdbc.query(
        "select servicio_id, insumo_id, cantidad from consumo_servicio",
        new MapSqlParameterSource(),
        rs -> {
          recetas
              .computeIfAbsent(rs.getObject("servicio_id", UUID.class), k -> new ArrayList<>())
              .add(
                  new LineaReceta(
                      rs.getObject("insumo_id", UUID.class), rs.getBigDecimal("cantidad")));
        });
    return recetas;
  }

  @Override
  public void reemplazar(UUID tenantId, UUID servicioId, List<LineaReceta> lineas) {
    jdbc.update(
        "delete from consumo_servicio where servicio_id = :servicioId",
        new MapSqlParameterSource("servicioId", servicioId));
    if (lineas.isEmpty()) {
      return;
    }
    jdbc.batchUpdate(
        "insert into consumo_servicio (tenant_id, servicio_id, insumo_id, cantidad)"
            + " values (:tenantId, :servicioId, :insumoId, :cantidad)",
        lineas.stream()
            .map(
                l ->
                    new MapSqlParameterSource()
                        .addValue("tenantId", tenantId)
                        .addValue("servicioId", servicioId)
                        .addValue("insumoId", l.insumoId())
                        .addValue("cantidad", l.cantidad()))
            .toArray(MapSqlParameterSource[]::new));
  }
}
