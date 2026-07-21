package com.lavadero.bootstrap;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Punto de entrada único del monolito modular.
 *
 * <p>{@code scanBasePackages = "com.lavadero"} es deliberado (en vez del default {@code
 * com.lavadero.bootstrap}): cada bounded context vive en su propio módulo Gradle/JAR
 * (`com.lavadero.tenant`, `com.lavadero.identity`, `com.lavadero.shared`, ...) pero todos se
 * ensamblan aquí en un solo proceso/classpath; sin este escaneo ampliado, Spring solo vería los
 * `@Component`/`@Service`/`@Repository`/`@RestController` de `bootstrap` mismo (que no tiene
 * ninguno) y la aplicación arrancaría sin beans de negocio.
 */
@SpringBootApplication(scanBasePackages = "com.lavadero")
public class Application {

  public static void main(String[] args) {
    SpringApplication.run(Application.class, args);
  }
}
