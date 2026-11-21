package com.lavadero.pruebas.inventariokafka;

import com.lavadero.catalog.application.usecase.ListarServiciosUseCase;
import com.lavadero.catalog.application.usecase.ObtenerServicioPorIdUseCase;
import com.lavadero.identity.infrastructure.security.TenantAwareTransactionAspect;
import com.lavadero.identity.infrastructure.security.TransactionManagementConfig;
import com.lavadero.inventory.InventoryTestApplication;
import java.time.Clock;
import org.mockito.Mockito;
import org.springframework.boot.SpringBootConfiguration;
import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.context.annotation.FilterType;
import org.springframework.context.annotation.Import;

/**
 * inventory + messaging (outbox, relay, Kafka) y el aspecto de tenant de producción: lo mismo que
 * arma `bootstrap` para este flujo, sin el resto de módulos. Vive fuera de {@code
 * com.lavadero.inventory} para que el escaneo de {@code InventoryTestApplication} no la recoja, y
 * excluye esa otra aplicación de test de su propio escaneo.
 */
@SpringBootConfiguration
@EnableAutoConfiguration
@ComponentScan(
    basePackages = {"com.lavadero.inventory", "com.lavadero.messaging"},
    excludeFilters =
        @ComponentScan.Filter(
            type = FilterType.ASSIGNABLE_TYPE,
            classes = InventoryTestApplication.class))
@Import({TenantAwareTransactionAspect.class, TransactionManagementConfig.class})
// El aspecto habilita el filtro de Hibernate `tenantFilter`, cuyo @FilterDef vive en
// SucursalJpaEntity (tenant-management): sin escanear esa entidad, Hibernate no lo conoce.
@EntityScan("com.lavadero.tenant.infrastructure.persistence")
public class InventoryKafkaTestApplication {

  @Bean
  Clock reloj() {
    return Clock.systemUTC();
  }

  @Bean
  ObtenerServicioPorIdUseCase obtenerServicioPorIdUseCase() {
    return Mockito.mock(ObtenerServicioPorIdUseCase.class);
  }

  @Bean
  ListarServiciosUseCase listarServiciosUseCase() {
    return Mockito.mock(ListarServiciosUseCase.class);
  }
}
