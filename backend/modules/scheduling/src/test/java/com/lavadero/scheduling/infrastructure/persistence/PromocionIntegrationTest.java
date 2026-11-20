package com.lavadero.scheduling.infrastructure.persistence;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.lavadero.scheduling.SchedulingTestApplication;
import com.lavadero.scheduling.domain.model.promocion.CodigoCupon;
import com.lavadero.scheduling.domain.model.promocion.Descuento;
import com.lavadero.scheduling.domain.model.promocion.FranjaHoraria;
import com.lavadero.scheduling.domain.model.promocion.Promocion;
import com.lavadero.scheduling.domain.repository.PromocionRepository;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.transaction.PlatformTransactionManager;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

/** Tabla `promocion` (V23): RLS, código único por lavadero, límite de usos y resultados. */
@SpringBootTest(classes = SchedulingTestApplication.class)
@Testcontainers
class PromocionIntegrationTest {

  private static final LocalDate HOY = LocalDate.of(2026, 11, 20);

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

  @Autowired private PromocionRepository promociones;
  @Autowired private JdbcTemplate jdbcTemplate;
  @Autowired private PlatformTransactionManager transactionManager;

  private RlsTestFixtures fixtures;
  private UUID tenant;

  @BeforeEach
  void setUp() {
    fixtures = new RlsTestFixtures(jdbcTemplate, transactionManager);
    tenant = fixtures.crearTenant("Lavadero promos");
  }

  @Test
  void guardaYLeeUnPrecioPorHorarioConSuFranja() {
    Promocion horaValle =
        Promocion.horario(
            tenant,
            "Mañanas",
            new FranjaHoraria(
                Set.of(DayOfWeek.MONDAY, DayOfWeek.SUNDAY),
                LocalTime.of(8, 0),
                LocalTime.of(11, 30)),
            Descuento.porcentaje(15),
            HOY,
            HOY.plusDays(30),
            Instant.now());
    fixtures.comoTenant(tenant, () -> promociones.save(horaValle));

    Promocion leida =
        fixtures.comoTenant(tenant, () -> promociones.findHorariosActivos()).getFirst();

    assertThat(leida.getFranja()).contains(horaValle.getFranja().orElseThrow());
    assertThat(leida.getDescuento().valor()).isEqualByComparingTo("15");
  }

  @Test
  void unLavaderoNoVeNiUsaLosCuponesDeOtro() {
    UUID otro = fixtures.crearTenant("Otro");
    fixtures.comoTenant(otro, () -> promociones.save(cupon(otro, "HOLA", null)));

    assertThat(
            fixtures.comoTenant(tenant, () -> promociones.findCuponActivo(CodigoCupon.de("HOLA"))))
        .isEmpty();
    // Y el mismo código sí se puede usar en este lavadero.
    fixtures.comoTenant(tenant, () -> promociones.save(cupon(tenant, "HOLA", null)));
    assertThat(fixtures.comoTenant(tenant, () -> promociones.listar())).hasSize(1);
  }

  @Test
  void dosCuponesActivosNoPuedenCompartirCodigoEnElMismoLavadero() {
    fixtures.comoTenant(tenant, () -> promociones.save(cupon(tenant, "DOBLE", null)));

    assertThatThrownBy(
            () -> fixtures.comoTenant(tenant, () -> promociones.save(cupon(tenant, "DOBLE", null))))
        .isInstanceOf(DataIntegrityViolationException.class);
  }

  @Test
  void elLimiteDeUsosAguantaPeticionesSimultaneasYDesactivarNoPisaElContador() throws Exception {
    Promocion cupon = cupon(tenant, "PRIMEROS", 3);
    fixtures.comoTenant(tenant, () -> promociones.save(cupon));

    int intentos = 10;
    CountDownLatch salida = new CountDownLatch(1);
    ExecutorService hilos = Executors.newFixedThreadPool(intentos);
    try {
      Callable<Boolean> usar =
          () -> {
            salida.await();
            return fixtures.comoTenant(tenant, () -> promociones.reservarUso(cupon.getId()));
          };
      var resultados = new java.util.ArrayList<Future<Boolean>>();
      for (int i = 0; i < intentos; i++) {
        resultados.add(hilos.submit(usar));
      }
      salida.countDown();
      long exitosos = 0;
      for (Future<Boolean> r : resultados) {
        exitosos += r.get() ? 1 : 0;
      }
      assertThat(exitosos).isEqualTo(3);
    } finally {
      hilos.shutdownNow();
    }

    // El agregado en memoria tiene usos = 0: guardarlo al desactivar no puede devolverlo a 0.
    cupon.desactivar();
    fixtures.comoTenant(tenant, () -> promociones.save(cupon));
    fixtures.comoTenant(
        tenant,
        () -> {
          promociones.liberarUso(cupon.getId());
          return null;
        });
    Promocion leida =
        fixtures.comoTenant(tenant, () -> promociones.findById(cupon.getId())).orElseThrow();
    assertThat(leida.getUsos()).isEqualTo(2);
    assertThat(leida.isActiva()).isFalse();
  }

  @Test
  void losResultadosCuentanReservasIngresosYDescuentoSinLasCanceladas() {
    UUID sucursal = fixtures.crearSucursal(tenant);
    UUID servicio = fixtures.crearServicio(tenant, "Lavado");
    UUID cliente = fixtures.crearUsuario(tenant);
    Promocion cupon = cupon(tenant, "RESULTADOS", null);
    fixtures.comoTenant(tenant, () -> promociones.save(cupon));
    reservaConPromocion(sucursal, servicio, cliente, cupon.getId(), "COMPLETADA");
    reservaConPromocion(sucursal, servicio, cliente, cupon.getId(), "PENDIENTE");
    reservaConPromocion(sucursal, servicio, cliente, cupon.getId(), "CANCELADA");

    var resultado = fixtures.comoTenant(tenant, () -> promociones.resultados()).get(cupon.getId());

    assertThat(resultado.reservas()).isEqualTo(2);
    assertThat(resultado.completadas()).isEqualTo(1);
    assertThat(resultado.ingresos().monto()).isEqualByComparingTo("13500");
    assertThat(resultado.descuentoOtorgado().monto()).isEqualByComparingTo("3000");
  }

  private void reservaConPromocion(
      UUID sucursal, UUID servicio, UUID cliente, UUID promocionId, String estado) {
    UUID reserva = fixtures.crearReserva(tenant, sucursal, servicio, cliente);
    fixtures.comoTenant(
        tenant,
        () ->
            jdbcTemplate.update(
                "update reserva set promocion_id = ?, precio_lista = 15000, precio = 13500, "
                    + "estado = ? where id = ?",
                promocionId,
                estado,
                reserva));
  }

  private static Promocion cupon(UUID tenantId, String codigo, Integer usosMaximos) {
    return Promocion.cupon(
        tenantId,
        "Cupón " + codigo,
        CodigoCupon.de(codigo),
        Descuento.porcentaje(10),
        HOY,
        HOY.plusDays(30),
        usosMaximos,
        Instant.now());
  }
}
