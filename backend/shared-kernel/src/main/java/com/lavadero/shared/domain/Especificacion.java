package com.lavadero.shared.domain;

/**
 * Patrón Specification: encapsula una regla de negocio evaluable y componible sobre un candidato de
 * tipo {@code T}. Vive en `domain` puro, sin dependencias externas, para poder combinarse en
 * cualquier capa.
 *
 * @param <T> tipo del candidato evaluado
 */
@FunctionalInterface
public interface Especificacion<T> {

  boolean isSatisfiedBy(T candidato);

  default Especificacion<T> and(Especificacion<T> otra) {
    return candidato -> this.isSatisfiedBy(candidato) && otra.isSatisfiedBy(candidato);
  }

  default Especificacion<T> or(Especificacion<T> otra) {
    return candidato -> this.isSatisfiedBy(candidato) || otra.isSatisfiedBy(candidato);
  }

  default Especificacion<T> not() {
    return candidato -> !this.isSatisfiedBy(candidato);
  }
}
