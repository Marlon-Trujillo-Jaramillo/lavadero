package com.lavadero.bootstrap.security;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import javax.sql.DataSource;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

/**
 * Convierte un bypass silencioso de Row Level Security en un fallo de arranque ruidoso.
 *
 * <p>El incidente real de este proyecto (ver docs/adr/0001-modular-monolith.md y memoria de sesión
 * "RLS superuser bypass bug") fue exactamente esto: el backend corría contra Postgres usando el rol
 * superusuario para las queries de negocio, y Postgres bypasea RLS para superusuarios sin excepción
 * — ninguna política protegía nada, en silencio, hasta que se corrió la app real. La configuración
 * de producción vive fuera de este repo (variables de entorno), así que no hay forma de "revisar el
 * código" para detectar esa misma regresión de config si vuelve a pasar.
 *
 * <p>Este chequeo corre una vez al arrancar, sobre el {@link DataSource} de runtime real (no el de
 * Flyway, que SÍ necesita ser superusuario para migraciones — ver V3__app_role.sql), y aborta el
 * arranque si el rol conectado resulta ser superusuario. La app "no arranca" es un fallo mucho más
 * seguro que "arranca y sirve tráfico sin aislamiento multi-tenant".
 */
@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class SuperuserBootGuard implements ApplicationRunner {

  private static final String QUERY_ROL_SUPERUSUARIO =
      "select rolsuper from pg_roles where rolname = current_user";

  private final DataSource dataSource;

  public SuperuserBootGuard(DataSource dataSource) {
    this.dataSource = dataSource;
  }

  @Override
  public void run(ApplicationArguments args) throws Exception {
    try (Connection connection = dataSource.getConnection();
        Statement statement = connection.createStatement();
        ResultSet resultSet = statement.executeQuery(QUERY_ROL_SUPERUSUARIO)) {
      String rolConectado = connection.getMetaData().getUserName();
      if (resultSet.next() && resultSet.getBoolean("rolsuper")) {
        throw new IllegalStateException(
            "El DataSource de runtime está conectado como '"
                + rolConectado
                + "', que es SUPERUSUARIO de Postgres. Un superusuario bypasea Row Level"
                + " Security sin excepción: TODO el aislamiento multi-tenant quedaría"
                + " desactivado en silencio. Verificar spring.datasource.username (debe ser el"
                + " rol de aplicación no-superusuario, p. ej. 'lavadero_app' — ver"
                + " V3__app_role.sql), nunca el rol usado para Flyway/migraciones.");
      }
    }
  }
}
