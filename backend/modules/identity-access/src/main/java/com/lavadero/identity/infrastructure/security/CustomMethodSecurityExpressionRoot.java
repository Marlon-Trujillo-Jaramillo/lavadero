package com.lavadero.identity.infrastructure.security;

import com.lavadero.shared.security.PrincipalAutenticado;
import java.util.UUID;
import org.springframework.security.access.expression.SecurityExpressionRoot;
import org.springframework.security.access.expression.method.MethodSecurityExpressionOperations;
import org.springframework.security.core.Authentication;

/**
 * Extiende las expresiones de {@code @PreAuthorize} con {@code hasSucursal(#sucursalId)}: verifica
 * que el usuario autenticado tenga esa sucursal asignada (claim {@code sucursal_id} del JWT). Usada
 * en {@code SucursalController#actualizar} y {@code EmpleadoController#crear} para que un
 * ADMIN_SUCURSAL solo pueda operar sobre su propia sucursal (ADMIN_TENANT no tiene esa
 * restricción).
 */
public class CustomMethodSecurityExpressionRoot extends SecurityExpressionRoot
    implements MethodSecurityExpressionOperations {

  private Object filterObject;
  private Object returnObject;
  private Object target;

  public CustomMethodSecurityExpressionRoot(Authentication authentication) {
    super(authentication);
  }

  public boolean hasSucursal(UUID sucursalId) {
    if (sucursalId == null) {
      return false;
    }
    Object principal = getAuthentication().getPrincipal();
    if (principal instanceof PrincipalAutenticado jwtPrincipal) {
      return sucursalId.equals(jwtPrincipal.sucursalId());
    }
    return false;
  }

  @Override
  public void setFilterObject(Object filterObject) {
    this.filterObject = filterObject;
  }

  @Override
  public Object getFilterObject() {
    return filterObject;
  }

  @Override
  public void setReturnObject(Object returnObject) {
    this.returnObject = returnObject;
  }

  @Override
  public Object getReturnObject() {
    return returnObject;
  }

  @Override
  public Object getThis() {
    return target;
  }

  public void setThis(Object target) {
    this.target = target;
  }
}
