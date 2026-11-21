package com.lavadero.archtests;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
import java.util.List;
import java.util.stream.Stream;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

/**
 * Verifica las reglas de Clean Architecture / módulos independientes que el resto del código solo
 * documenta en comentarios (ver, p. ej., {@code AggregateRoot}, {@code UseCase} en shared-kernel, o
 * los build.gradle.kts de cada bounded context). Escanea el bytecode compilado de todos los módulos
 * de negocio ya ensamblados como dependencias de test de este módulo.
 */
class LayeredArchitectureTest {

  private static JavaClasses clases;

  @BeforeAll
  static void importar() {
    clases =
        new ClassFileImporter()
            .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
            .importPackages("com.lavadero");
  }

  @Test
  void elDominioNoDependeDeSpringNiJpa() {
    ArchRule regla =
        noClasses()
            .that()
            .resideInAPackage("..domain..")
            .should()
            .dependOnClassesThat()
            .resideInAnyPackage("org.springframework..", "jakarta.persistence..");
    regla.check(clases);
  }

  @Test
  void laAplicacionNoDependeDeInfraestructuraNiDeInterfaces() {
    ArchRule regla =
        noClasses()
            .that()
            .resideInAPackage("..application..")
            .should()
            .dependOnClassesThat()
            .resideInAnyPackage("..infrastructure..", "..interfaces..");
    regla.check(clases);
  }

  @Test
  void tenantManagementNoDependeDeIdentityAccess() {
    ArchRule regla =
        noClasses()
            .that()
            .resideInAPackage("com.lavadero.tenant..")
            .should()
            .dependOnClassesThat()
            .resideInAPackage("com.lavadero.identity..");
    regla.check(clases);
  }

  /**
   * scheduling es el módulo "de arriba": depende de tenant-management/catalog/identity-access,
   * ninguno de esos tres depende (ni debe depender) de él — ver build.gradle.kts de scheduling.
   */
  @Test
  void ningunOtroModuloDeNegocioDependeDeScheduling() {
    ArchRule regla =
        noClasses()
            .that()
            .resideInAnyPackage(
                "com.lavadero.tenant..",
                "com.lavadero.catalog..",
                "com.lavadero.identity..",
                "com.lavadero.inventory..")
            .should()
            .dependOnClassesThat()
            .resideInAPackage("com.lavadero.scheduling..");
    regla.check(clases);
  }

  /**
   * catalog es una hoja: el resto lo consume (vía su capa `application`), él no depende de ningún
   * otro módulo de negocio. Su build.gradle.kts solo trae tenant-management como
   * testImplementation; esto lo hace cumplir también en el código de producción.
   */
  @Test
  void catalogNoDependeDeOtrosModulosDeNegocio() {
    ArchRule regla =
        noClasses()
            .that()
            .resideInAPackage("com.lavadero.catalog..")
            .should()
            .dependOnClassesThat()
            .resideInAnyPackage(
                "com.lavadero.tenant..",
                "com.lavadero.identity..",
                "com.lavadero.scheduling..",
                "com.lavadero.inventory..");
    regla.check(clases);
  }

  /**
   * Entre módulos solo se habla por la capa `application` (casos de uso + DTOs). Importar la
   * `infrastructure`/`interfaces` de otro módulo acopla a sus detalles internos: así se coló
   * scheduling usando el principal JWT de identity-access, que ahora vive en shared-kernel.
   */
  @Test
  void ningunModuloUsaLaInfraestructuraNiLasInterfacesDeOtro() {
    List<String> modulos = List.of("tenant", "identity", "catalog", "scheduling", "inventory");
    for (String modulo : modulos) {
      String[] internosDeOtros =
          modulos.stream()
              .filter(otro -> !otro.equals(modulo))
              .flatMap(
                  otro ->
                      Stream.of(
                          "com.lavadero." + otro + ".infrastructure..",
                          "com.lavadero." + otro + ".interfaces.."))
              .toArray(String[]::new);
      noClasses()
          .that()
          .resideInAPackage("com.lavadero." + modulo + "..")
          .should()
          .dependOnClassesThat()
          .resideInAnyPackage(internosDeOtros)
          .check(clases);
    }
  }

  /**
   * inventory es una hoja "de abajo hacia arriba": reacciona a eventos de scheduling (vía
   * `contracts`) y lee precios de catalog, pero ningún módulo depende de él. Quitarlo del build no
   * debe romper a nadie.
   */
  @Test
  void ningunModuloDependeDeInventory() {
    noClasses()
        .that()
        .resideInAnyPackage(
            "com.lavadero.tenant..",
            "com.lavadero.catalog..",
            "com.lavadero.identity..",
            "com.lavadero.scheduling..")
        .should()
        .dependOnClassesThat()
        .resideInAPackage("com.lavadero.inventory..")
        .check(clases);
  }

  /**
   * messaging es infraestructura compartida (outbox, relay, Kafka): los módulos dependen de él para
   * recibir eventos, nunca al revés. Si messaging conociera un módulo, agregar un evento nuevo
   * obligaría a tocar la mensajería.
   */
  @Test
  void messagingNoConoceNingunModuloDeNegocio() {
    noClasses()
        .that()
        .resideInAPackage("com.lavadero.messaging..")
        .should()
        .dependOnClassesThat()
        .resideInAnyPackage(
            "com.lavadero.tenant..",
            "com.lavadero.catalog..",
            "com.lavadero.identity..",
            "com.lavadero.scheduling..",
            "com.lavadero.inventory..")
        .check(clases);
  }
}
