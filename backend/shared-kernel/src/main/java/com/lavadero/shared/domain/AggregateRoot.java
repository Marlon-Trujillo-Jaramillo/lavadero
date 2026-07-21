package com.lavadero.shared.domain;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

/**
 * Base para todo aggregate root del dominio. Encapsula el identificador y el registro de eventos de
 * dominio pendientes de publicar (patrón "eventos acumulados", publicados por la capa de aplicación
 * después de persistir).
 *
 * <p>Deliberadamente NO tiene ninguna anotación de framework (ni JPA ni Spring): esta clase vive en
 * `domain` y las reglas de arquitectura (ArchUnit, ver módulo `architecture-tests`) prohíben que
 * `domain` dependa de `org.springframework..` o `jakarta.persistence..`.
 *
 * @param <ID> tipo del identificador del aggregate (p. ej. {@link TenantId} o UUID)
 */
public abstract class AggregateRoot<ID> {

  private final ID id;
  private final transient List<DomainEvent> eventosDominio = new ArrayList<>();

  protected AggregateRoot(ID id) {
    this.id = Objects.requireNonNull(id, "id no puede ser nulo");
  }

  public ID getId() {
    return id;
  }

  protected void registrar(DomainEvent evento) {
    this.eventosDominio.add(Objects.requireNonNull(evento));
  }

  public List<DomainEvent> eventosPendientes() {
    return Collections.unmodifiableList(eventosDominio);
  }

  public void limpiarEventos() {
    this.eventosDominio.clear();
  }

  @Override
  public boolean equals(Object o) {
    if (this == o) {
      return true;
    }
    if (!(o instanceof AggregateRoot<?> that)) {
      return false;
    }
    return Objects.equals(id, that.id);
  }

  @Override
  public int hashCode() {
    return Objects.hash(id);
  }
}
