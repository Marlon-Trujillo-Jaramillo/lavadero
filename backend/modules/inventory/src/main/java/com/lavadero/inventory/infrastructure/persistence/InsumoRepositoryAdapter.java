package com.lavadero.inventory.infrastructure.persistence;

import com.lavadero.inventory.domain.model.Insumo;
import com.lavadero.inventory.domain.model.UnidadMedida;
import com.lavadero.inventory.domain.repository.InsumoRepository;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Currency;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.namedparam.MapSqlParameterSource;
import org.springframework.jdbc.core.namedparam.NamedParameterJdbcTemplate;
import org.springframework.stereotype.Repository;

/**
 * El inventario va en SQL directo ({@link NamedParameterJdbcTemplate}) en vez de JPA: sus
 * escrituras importantes son sumas atómicas ({@code UPSERT ... RETURNING}) que JPA no expresa bien,
 * y las tablas son pequeñas. RLS aplica igual: la consulta corre en la transacción del caso de uso,
 * que ya fijó {@code app.current_tenant_id}.
 */
@Repository
class InsumoRepositoryAdapter implements InsumoRepository {

  private static final String COLUMNAS =
      "id, tenant_id, nombre, unidad, costo_unitario, moneda, activo, creado_en";

  private final NamedParameterJdbcTemplate jdbc;

  InsumoRepositoryAdapter(NamedParameterJdbcTemplate jdbc) {
    this.jdbc = jdbc;
  }

  @Override
  public Insumo save(Insumo i) {
    jdbc.update(
        "insert into insumo ("
            + COLUMNAS
            + ") values (:id, :tenantId, :nombre, :unidad, :costo, :moneda, :activo, :creadoEn)"
            + " on conflict (id) do update set nombre = excluded.nombre,"
            + " costo_unitario = excluded.costo_unitario, activo = excluded.activo",
        new MapSqlParameterSource()
            .addValue("id", i.getId())
            .addValue("tenantId", i.getTenantId())
            .addValue("nombre", i.getNombre())
            .addValue("unidad", i.getUnidad().name())
            .addValue("costo", i.getCostoUnitario())
            .addValue("moneda", i.getMoneda().getCurrencyCode())
            .addValue("activo", i.isActivo())
            .addValue("creadoEn", Timestamp.from(i.getCreadoEn())));
    return i;
  }

  @Override
  public Optional<Insumo> findById(UUID id) {
    return jdbc
        .query(
            "select " + COLUMNAS + " from insumo where id = :id",
            new MapSqlParameterSource("id", id),
            (rs, n) -> mapear(rs))
        .stream()
        .findFirst();
  }

  @Override
  public List<Insumo> listarActivos() {
    return jdbc.query(
        "select " + COLUMNAS + " from insumo where activo order by lower(nombre)",
        new MapSqlParameterSource(),
        (rs, n) -> mapear(rs));
  }

  @Override
  public boolean existeActivoConNombre(String nombre) {
    Boolean existe =
        jdbc.queryForObject(
            "select exists (select 1 from insumo where activo and lower(nombre) = lower(:nombre))",
            new MapSqlParameterSource("nombre", nombre.strip()),
            Boolean.class);
    return Boolean.TRUE.equals(existe);
  }

  private static Insumo mapear(ResultSet rs) throws SQLException {
    return new Insumo(
        rs.getObject("id", UUID.class),
        rs.getObject("tenant_id", UUID.class),
        rs.getString("nombre"),
        UnidadMedida.valueOf(rs.getString("unidad")),
        rs.getBigDecimal("costo_unitario"),
        Currency.getInstance(rs.getString("moneda")),
        rs.getBoolean("activo"),
        rs.getTimestamp("creado_en").toInstant());
  }
}
