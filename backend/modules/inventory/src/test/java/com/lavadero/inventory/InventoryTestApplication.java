package com.lavadero.inventory;

import com.lavadero.catalog.application.usecase.ListarServiciosUseCase;
import com.lavadero.catalog.application.usecase.ObtenerServicioPorIdUseCase;
import java.time.Clock;
import org.mockito.Mockito;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;

/**
 * Aplicación mínima de test (inventory es un módulo librería). Los casos de uso de `catalog` que
 * usa inventory se reemplazan por mocks: aquí se prueba inventory, no catalog.
 */
@SpringBootApplication
public class InventoryTestApplication {

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
