package com.lavadero.shared.application;

/**
 * Contrato funcional para todo caso de uso de la capa de aplicación. Cada caso de uso recibe un
 * input inmutable (comando o query) y produce un output; la orquestación de dominio + puertos
 * ocurre dentro de {@code execute}. No conocer Spring/JPA aquí es intencional: `application` no
 * puede importar `infrastructure` ni `interfaces` (regla verificada por ArchUnit en el módulo
 * `architecture-tests`).
 *
 * @param <I> tipo del input (comando/consulta)
 * @param <O> tipo del resultado
 */
@FunctionalInterface
public interface UseCase<I, O> {
  O execute(I input);
}
