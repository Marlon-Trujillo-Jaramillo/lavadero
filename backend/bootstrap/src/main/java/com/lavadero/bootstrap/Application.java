package com.lavadero.bootstrap;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

/**
 * Punto de entrada único del monolito modular.
 *
 * <p>{@code scanBasePackages = "com.lavadero"} es deliberado (en vez del default {@code
 * com.lavadero.bootstrap}): cada bounded context vive en su propio módulo Gradle/JAR
 * (`com.lavadero.tenant`, `com.lavadero.identity`, `com.lavadero.shared`, ...) pero todos se
 * ensamblan aquí en un solo proceso/classpath; sin este escaneo ampliado, Spring solo vería los
 * `@Component`/`@Service`/`@Repository`/`@RestController` de `bootstrap` mismo (que no tiene
 * ninguno) y la aplicación arrancaría sin beans de negocio.
 *
 * <p>{@code @EnableJpaRepositories}/{@code @EntityScan} explícitos son necesarios ADEMÁS de lo
 * anterior: el descubrimiento de interfaces {@code JpaRepository}/entidades {@code @Entity} de
 * Spring Data NO se rige por {@code scanBasePackages} de {@code @ComponentScan} — usa {@code
 * AutoConfigurationPackages}, que por defecto es solo el paquete de esta clase ({@code
 * com.lavadero.bootstrap}), no el `scanBasePackages` de arriba. Sin esto, la app arranca pero cero
 * repositorios/entidades de los módulos de negocio quedan registrados (se detectó al intentar
 * correr la app real por primera vez — los tests nunca lo cubrieron porque cada uno usa su propia
 * `@SpringBootApplication` ya declarada dentro del paquete de su propio módulo).
 */
@SpringBootApplication(scanBasePackages = "com.lavadero")
@EnableJpaRepositories(basePackages = "com.lavadero")
@EntityScan(basePackages = "com.lavadero")
public class Application {

  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }
}
