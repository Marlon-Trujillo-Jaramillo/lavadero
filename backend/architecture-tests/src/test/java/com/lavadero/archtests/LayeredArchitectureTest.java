package com.lavadero.archtests;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.lang.ArchRule;
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
                "com.lavadero.tenant..", "com.lavadero.catalog..", "com.lavadero.identity..")
            .should()
            .dependOnClassesThat()
            .resideInAPackage("com.lavadero.scheduling..");
    regla.check(clases);
  }
}
