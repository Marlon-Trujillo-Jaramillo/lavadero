package com.lavadero.bootstrap.web;

import com.lavadero.shared.application.exception.ApplicationException;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.application.exception.ValidationException;
import jakarta.servlet.http.HttpServletRequest;
import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

/**
 * Traductor centralizado de excepciones a respuestas HTTP consistentes: {@code {timestamp, status,
 * error, message, path}}. Vive en `bootstrap` (no en `shared-kernel`) porque requiere Spring Web,
 * que `shared-kernel` deliberadamente no tiene como dependencia (ver su build.gradle.kts:
 * `application` no puede conocer HTTP).
 *
 * <p>Nunca expone stack traces ni mensajes internos de excepciones no controladas: solo el mensaje
 * de negocio de las {@link ApplicationException} conocidas. Cualquier otra excepción se traduce a
 * un mensaje genérico (el detalle real queda solo en los logs del servidor).
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

  private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

  @ExceptionHandler(NotFoundException.class)
  public ResponseEntity<ErrorResponse> handleNotFound(
      NotFoundException ex, HttpServletRequest request) {
    return build(HttpStatus.NOT_FOUND, ex.getMessage(), request);
  }

  @ExceptionHandler(ValidationException.class)
  public ResponseEntity<ErrorResponse> handleValidation(
      ValidationException ex, HttpServletRequest request) {
    return build(HttpStatus.BAD_REQUEST, ex.getMessage(), request);
  }

  @ExceptionHandler(ForbiddenException.class)
  public ResponseEntity<ErrorResponse> handleForbidden(
      ForbiddenException ex, HttpServletRequest request) {
    return build(HttpStatus.FORBIDDEN, ex.getMessage(), request);
  }

  /**
   * `@PreAuthorize` deniega lanzando esto (Spring Security 6), no {@link ForbiddenException} — sin
   * este handler caía en {@link #handleUnexpected}, devolviendo 500 en vez de 403 para cualquier
   * usuario autenticado sin el rol requerido (nunca antes ejercitado con una llamada real de un rol
   * insuficiente contra un endpoint protegido).
   */
  @ExceptionHandler(AuthorizationDeniedException.class)
  public ResponseEntity<ErrorResponse> handleAuthorizationDenied(
      AuthorizationDeniedException ex, HttpServletRequest request) {
    return build(HttpStatus.FORBIDDEN, "No tienes permiso para esta acción", request);
  }

  @ExceptionHandler(ApplicationException.class)
  public ResponseEntity<ErrorResponse> handleApplication(
      ApplicationException ex, HttpServletRequest request) {
    return build(HttpStatus.BAD_REQUEST, ex.getMessage(), request);
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorResponse> handleBeanValidation(
      MethodArgumentNotValidException ex, HttpServletRequest request) {
    String message =
        ex.getBindingResult().getFieldErrors().stream()
            .map(FieldError::getDefaultMessage)
            .findFirst()
            .orElse("Solicitud inválida");
    return build(HttpStatus.BAD_REQUEST, message, request);
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorResponse> handleUnexpected(Exception ex, HttpServletRequest request) {
    log.error("Error interno no controlado en {}", request.getRequestURI(), ex);
    return build(HttpStatus.INTERNAL_SERVER_ERROR, "Error interno inesperado", request);
  }

  private ResponseEntity<ErrorResponse> build(
      HttpStatus status, String message, HttpServletRequest request) {
    ErrorResponse body =
        new ErrorResponse(
            Instant.now(),
            status.value(),
            status.getReasonPhrase(),
            message,
            request.getRequestURI());
    return ResponseEntity.status(status).body(body);
  }

  public record ErrorResponse(
      Instant timestamp, int status, String error, String message, String path) {}
}
