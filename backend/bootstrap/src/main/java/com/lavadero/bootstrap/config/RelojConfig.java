package com.lavadero.bootstrap.config;

import java.time.Clock;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Reloj inyectable para los casos de uso que comparan contra "ahora" (ventana de antigüedad del
 * webhook de pagos, reuso de pagos pendientes, bloqueo de login). Vive en {@code bootstrap}: es
 * cableado transversal del proceso, no de un bounded context. Los tests de cada módulo declaran su
 * propio {@link Clock} (fijo o del sistema) en vez de depender de escanear otro módulo.
 */
@Configuration
public class RelojConfig {

  @Bean
  @ConditionalOnMissingBean
  public Clock reloj() {
    return Clock.systemUTC();
  }
}
