package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.ReservaEstado;
import com.lavadero.scheduling.domain.model.crm.ClienteResumen;
import com.lavadero.scheduling.domain.model.crm.FiltroClientes;
import com.lavadero.scheduling.domain.model.crm.OrdenClientes;
import com.lavadero.scheduling.domain.model.crm.PaginaClientes;
import com.lavadero.scheduling.domain.model.crm.SegmentoCliente;
import com.lavadero.scheduling.domain.repository.ClienteCrmRepository;
import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/**
 * La segmentación del CRM vive en SQL (ver {@code ClienteCrmRepositoryAdapter}), así que se prueba
 * contra Postgres real: cada segmento, el ritmo propio de cada cliente, el alcance por sucursal y
 * el aislamiento entre lavaderos.
 */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class ClienteCrmIntegrationTest {

  private static final Instant AHORA = Instant.parse("2026-11-20T12:00:00Z");

  @Container
  static final PostgreSQLContainer<?> POSTGRES =
      new PostgreSQLContainer<>("postgres:16-alpine").withDatabaseName("lavadero_test");

  @DynamicPropertySource
  static void datasourceProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.flyway.url", POSTGRES::getJdbcUrl);
    registry.add("spring.flyway.user", POSTGRES::getUsername);
    registry.add("spring.flyway.password", POSTGRES::getPassword);
    registry.add("spring.datasource.url", POSTGRES::getJdbcUrl);
    registry.add("spring.datasource.username", () -> "lavadero_app");
    registry.add("spring.datasource.password", () -> "lavadero_app");
  }

  @Autowired private ClienteCrmRepository crm;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  private RlsTestFixtures fixtures;
  private UUID tenant;
  private UUID sucursal;
  private UUID lavado;
  private UUID polichado;

  @BeforeEach
  void setUp() {
    fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);
    tenant = fixtures.crearTenant("Lavadero CRM");
    sucursal = fixtures.crearSucursal(tenant);
    lavado = fixtures.crearServicio(tenant, "Lavado");
    polichado = fixtures.crearServicio(tenant, "Polichado");
  }

  @Test
  void clasificaCadaClienteSegunSuPropioRitmo() {
    UUID frecuente = cliente("Frecuente");
    visitasCadaNDias(frecuente, 5, 10, 5);
    UUID enRiesgo = cliente("En riesgo");
    visitasCadaNDias(enRiesgo, 3, 10, 40);
    UUID conProxima = cliente("Con próxima reserva");
    visitasCadaNDias(conProxima, 3, 10, 40);
    reserva(conProxima, lavado, AHORA.plus(Duration.ofDays(2)), ReservaEstado.PENDIENTE);
    UUID nuevo = cliente("Nuevo");
    visitasCadaNDias(nuevo, 1, 0, 10);
    UUID unaVisitaLejana = cliente("Una visita lejana");
    visitasCadaNDias(unaVisitaLejana, 1, 0, 61);
    UUID unaVisitaMedia = cliente("Una visita media");
    visitasCadaNDias(unaVisitaMedia, 1, 0, 45);
    UUID ritmoLento = cliente("Ritmo lento");
    visitasCadaNDias(ritmoLento, 4, 40, 50);
    UUID soloCancelo = cliente("Solo canceló");
    reserva(soloCancelo, lavado, AHORA.minus(Duration.ofDays(3)), ReservaEstado.CANCELADA);
    UUID sinReservas = cliente("Sin reservas");
    usuarioConRol("Empleado", "EMPLEADO");

    Map<UUID, SegmentoCliente> segmentos =
        buscar(filtro(null, null, OrdenClientes.NOMBRE, null, 0, 50)).clientes().stream()
            .collect(Collectors.toMap(ClienteResumen::id, ClienteResumen::segmento));

    assertThat(segmentos)
        .containsEntry(frecuente, SegmentoCliente.FRECUENTE)
        .containsEntry(enRiesgo, SegmentoCliente.EN_RIESGO)
        .containsEntry(conProxima, SegmentoCliente.OCASIONAL)
        .containsEntry(nuevo, SegmentoCliente.NUEVO)
        .containsEntry(unaVisitaLejana, SegmentoCliente.EN_RIESGO)
        .containsEntry(unaVisitaMedia, SegmentoCliente.OCASIONAL)
        // Vuelve cada 40 días: a los 50 todavía no es raro (umbral = 2 × 40).
        .containsEntry(ritmoLento, SegmentoCliente.OCASIONAL)
        .containsEntry(soloCancelo, SegmentoCliente.SIN_VISITAS)
        .containsEntry(sinReservas, SegmentoCliente.SIN_VISITAS)
        .hasSize(9); // el empleado no es cliente
  }

  @Test
  void calculaVisitasGastoYProximaReservaYCuentaPorSegmento() {
    UUID ana = cliente("Ana");
    reserva(ana, lavado, AHORA.minus(Duration.ofDays(20)), ReservaEstado.COMPLETADA);
    reserva(ana, polichado, AHORA.minus(Duration.ofDays(5)), ReservaEstado.COMPLETADA);
    reserva(ana, lavado, AHORA.minus(Duration.ofDays(1)), ReservaEstado.CANCELADA);
    Instant proxima = AHORA.plus(Duration.ofDays(3));
    reserva(ana, lavado, proxima, ReservaEstado.PENDIENTE);
    cliente("Beto");

    PaginaClientes pagina = buscar(filtro(null, null, OrdenClientes.GASTO, null, 0, 10));

    ClienteResumen resumenAna = pagina.clientes().get(0);
    assertThat(resumenAna.id()).isEqualTo(ana);
    assertThat(resumenAna.visitas()).isEqualTo(2);
    assertThat(resumenAna.gastoTotal().monto()).isEqualByComparingTo(new BigDecimal("30000"));
    assertThat(resumenAna.ultimaVisita()).isEqualTo(AHORA.minus(Duration.ofDays(5)));
    assertThat(resumenAna.proximaReserva()).isEqualTo(proxima);
    assertThat(pagina.total()).isEqualTo(2);
    assertThat(pagina.porSegmento())
        .containsEntry(SegmentoCliente.NUEVO, 1L)
        .containsEntry(SegmentoCliente.SIN_VISITAS, 1L)
        .containsEntry(SegmentoCliente.FRECUENTE, 0L);
  }

  @Test
  void filtraPorSegmentoBuscaYPagina() {
    for (int i = 1; i <= 5; i++) {
      UUID c = cliente("Cliente " + i);
      visitasCadaNDias(c, 1, 0, i);
    }
    UUID porcentaje = cliente("100% fiel");
    visitasCadaNDias(porcentaje, 1, 0, 90);

    PaginaClientes segunda =
        buscar(filtro(SegmentoCliente.NUEVO, null, OrdenClientes.NOMBRE, null, 1, 2));
    assertThat(segunda.total()).isEqualTo(5);
    assertThat(segunda.clientes())
        .extracting(ClienteResumen::nombre)
        .containsExactly("Cliente 3", "Cliente 4");

    // "%" es literal: no trae a todos.
    assertThat(buscar(filtro(null, "0%", OrdenClientes.NOMBRE, null, 0, 10)).clientes())
        .extracting(ClienteResumen::id)
        .containsExactly(porcentaje);
    assertThat(buscar(filtro(null, "CLIENTE 2", OrdenClientes.NOMBRE, null, 0, 10)).total())
        .isEqualTo(1);
  }

  @Test
  void conSucursalSoloCuentaLoDeEsaSucursal() {
    UUID otraSucursal = fixtures.crearSucursal(tenant);
    UUID ambas = cliente("En ambas");
    reserva(ambas, lavado, AHORA.minus(Duration.ofDays(2)), ReservaEstado.COMPLETADA);
    reservaEn(
        otraSucursal, ambas, lavado, AHORA.minus(Duration.ofDays(4)), ReservaEstado.COMPLETADA);
    UUID soloOtra = cliente("Solo en la otra");
    reservaEn(
        otraSucursal, soloOtra, lavado, AHORA.minus(Duration.ofDays(4)), ReservaEstado.COMPLETADA);
    cliente("Sin reservas");

    PaginaClientes deLaSucursal = buscar(filtro(null, null, OrdenClientes.NOMBRE, sucursal, 0, 10));

    assertThat(deLaSucursal.clientes()).extracting(ClienteResumen::id).containsExactly(ambas);
    assertThat(deLaSucursal.clientes().get(0).visitas()).isEqualTo(1);
    assertThat(fixtures.comoTenant(tenant, () -> crm.resumen(soloOtra, sucursal, AHORA))).isEmpty();
    assertThat(fixtures.comoTenant(tenant, () -> crm.historial(ambas, sucursal, 20))).hasSize(1);
  }

  @Test
  void unLavaderoNuncaVeLosClientesDeOtro() {
    UUID propio = cliente("Propio");
    UUID otroTenant = fixtures.crearTenant("Otro lavadero");
    UUID ajeno = fixtures.crearUsuario(otroTenant);
    fixtures.comoTenant(
        otroTenant,
        () ->
            jdbcTemplate.update(
                "insert into usuario_rol (usuario_id, rol) values (?, 'CLIENTE')", ajeno));

    assertThat(buscar(filtro(null, null, OrdenClientes.NOMBRE, null, 0, 10)).clientes())
        .extracting(ClienteResumen::id)
        .containsExactly(propio);
    assertThat(fixtures.comoTenant(tenant, () -> crm.resumen(ajeno, null, AHORA))).isEmpty();
  }

  @Test
  void laFichaTraeHistorialRecienteYServicioFavorito() {
    UUID ana = cliente("Ana");
    reserva(ana, polichado, AHORA.minus(Duration.ofDays(30)), ReservaEstado.COMPLETADA);
    reserva(ana, lavado, AHORA.minus(Duration.ofDays(20)), ReservaEstado.COMPLETADA);
    reserva(ana, lavado, AHORA.minus(Duration.ofDays(10)), ReservaEstado.COMPLETADA);
    reserva(ana, polichado, AHORA.minus(Duration.ofDays(1)), ReservaEstado.CANCELADA);

    var historial = fixtures.comoTenant(tenant, () -> crm.historial(ana, null, 3));
    assertThat(historial).hasSize(3);
    assertThat(historial.get(0).estado()).isEqualTo(ReservaEstado.CANCELADA);
    assertThat(historial.get(0).servicio()).isEqualTo("Polichado");
    assertThat(fixtures.comoTenant(tenant, () -> crm.servicioFavorito(ana, null)))
        .contains("Lavado");
  }

  private PaginaClientes buscar(FiltroClientes filtro) {
    return fixtures.comoTenant(tenant, () -> crm.buscar(filtro));
  }

  private static FiltroClientes filtro(
      SegmentoCliente segmento,
      String q,
      OrdenClientes orden,
      UUID sucursal,
      int pagina,
      int tamano) {
    return new FiltroClientes(segmento, q, orden, sucursal, pagina, tamano, AHORA);
  }

  private UUID cliente(String nombre) {
    return usuarioConRol(nombre, "CLIENTE");
  }

  private UUID usuarioConRol(String nombre, String rol) {
    UUID id = UUID.randomUUID();
    fixtures.comoTenant(
        tenant,
        () -> {
          jdbcTemplate.update(
              "insert into usuario (id, tenant_id, email, nombre, password_hash, estado) "
                  + "values (?, ?, ?, ?, 'hash', 'ACTIVO')",
              id,
              tenant,
              id + "@example.com",
              nombre);
          return jdbcTemplate.update(
              "insert into usuario_rol (usuario_id, rol) values (?, ?)", id, rol);
        });
    return id;
  }

  /**
   * {@code cantidad} visitas completadas, una cada {@code cadaDias}, la última hace {@code
   * haceDias}.
   */
  private void visitasCadaNDias(UUID clienteId, int cantidad, int cadaDias, int haceDias) {
    for (int i = 0; i < cantidad; i++) {
      Instant fecha = AHORA.minus(Duration.ofDays(haceDias + (long) i * cadaDias));
      reserva(clienteId, lavado, fecha, ReservaEstado.COMPLETADA);
    }
  }

  private void reserva(UUID clienteId, UUID servicioId, Instant inicio, ReservaEstado estado) {
    reservaEn(sucursal, clienteId, servicioId, inicio, estado);
  }

  private void reservaEn(
      UUID sucursalId, UUID clienteId, UUID servicioId, Instant inicio, ReservaEstado estado) {
    fixtures.comoTenant(
        tenant,
        () ->
            jdbcTemplate.update(
                "insert into reserva (id, tenant_id, sucursal_id, servicio_id, cliente_id, "
                    + "fecha_hora_inicio, fecha_hora_fin, duracion_estimada_minutos, precio, moneda, estado) "
                    + "values (?, ?, ?, ?, ?, ?, ?, 20, 15000, 'COP', ?)",
                UUID.randomUUID(),
                tenant,
                sucursalId,
                servicioId,
                clienteId,
                Timestamp.from(inicio),
                Timestamp.from(inicio.plus(Duration.ofMinutes(20))),
                estado.name()));
  }
}
