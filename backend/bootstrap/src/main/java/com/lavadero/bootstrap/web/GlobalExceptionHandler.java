package com.lavadero.bootstrap.web;

import com.lavadero.shared.application.exception.ApplicationException;
import com.lavadero.shared.application.exception.DemasiadosIntentosException;
import com.lavadero.shared.application.exception.ForbiddenException;
import com.lavadero.shared.application.exception.NotFoundException;
import com.lavadero.shared.application.exception.ValidationException;
import jakarta.servlet.http.HttpServletRequest;
import java.time.DateTimeException;
import java.time.Instant;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.authorization.AuthorizationDeniedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

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

  @ExceptionHandler(DemasiadosIntentosException.class)
  public ResponseEntity<ErrorResponse> handleDemasiadosIntentos(
      DemasiadosIntentosException ex, HttpServletRequest request) {
    return build(HttpStatus.TOO_MANY_REQUESTS, ex.getMessage(), request);
  }

  /**
   * Una fecha fuera del rango representable (p. ej. {@code +999999999-12-31} en un query param)
   * revienta al convertirla a {@code Instant}: es un error del cliente, no del servidor.
   */
  @ExceptionHandler(DateTimeException.class)
  public ResponseEntity<ErrorResponse> handleFechaInvalida(
      DateTimeException ex, HttpServletRequest request) {
    return build(HttpStatus.BAD_REQUEST, "Fecha fuera de rango", request);
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

  /**
   * Dos altas simultáneas con el mismo valor único (email por tenant, slug) pasan ambas el {@code
   * existsBy...} previo y la segunda choca con el índice único. Es un conflicto del cliente, no un
   * fallo del servidor.
   */
  @ExceptionHandler(DataIntegrityViolationException.class)
  public ResponseEntity<ErrorResponse> handleDataIntegrity(
      DataIntegrityViolationException ex, HttpServletRequest request) {
    log.warn("Violación de integridad en {}: {}", request.getRequestURI(), ex.getMessage());
    return build(
        HttpStatus.CONFLICT, "El recurso ya existe o entra en conflicto con otro", request);
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

  /**
   * Errores de forma de la petición: un query param que no se puede convertir ({@code
   * servicioId=abc}, una fecha mal escrita), uno obligatorio que falta, o un cuerpo que no es JSON
   * válido o trae un valor imposible (una hora {@code "25:00"}). Son del cliente: 400 con un
   * mensaje que nombra el parámetro, sin el detalle interno del parser.
   */
  @ExceptionHandler(MethodArgumentTypeMismatchException.class)
  public ResponseEntity<ErrorResponse> handleParametroInvalido(
      MethodArgumentTypeMismatchException ex, HttpServletRequest request) {
    return build(
        HttpStatus.BAD_REQUEST,
        "El parámetro '%s' tiene un formato inválido".formatted(ex.getName()),
        request);
  }

  @ExceptionHandler(MissingServletRequestParameterException.class)
  public ResponseEntity<ErrorResponse> handleParametroFaltante(
      MissingServletRequestParameterException ex, HttpServletRequest request) {
    return build(
        HttpStatus.BAD_REQUEST,
        "Falta el parámetro '%s'".formatted(ex.getParameterName()),
        request);
  }

  @ExceptionHandler(HttpMessageNotReadableException.class)
  public ResponseEntity<ErrorResponse> handleCuerpoIlegible(
      HttpMessageNotReadableException ex, HttpServletRequest request) {
    return build(
        HttpStatus.BAD_REQUEST,
        "El cuerpo de la solicitud no es válido: revisa el formato de los campos",
        request);
  }

  /**
   * Los agregados protegen sus reglas con {@code IllegalStateException} (transición inválida, p.
   * ej. completar una reserva que no ha iniciado) e {@code IllegalArgumentException} (dato
   * inválido, p. ej. una placa mal escrita). Antes caían en el 500 genérico. Solo se traducen las
   * que nacen en el dominio de Lavadero: las de librerías siguen siendo errores internos y no
   * exponen su mensaje.
   */
  @ExceptionHandler({IllegalStateException.class, IllegalArgumentException.class})
  public ResponseEntity<ErrorResponse> handleReglaDeDominio(
      RuntimeException ex, HttpServletRequest request) {
    if (!lanzadaPorElDominio(ex)) {
      return handleUnexpected(ex, request);
    }
    HttpStatus status =
        ex instanceof IllegalStateException ? HttpStatus.CONFLICT : HttpStatus.BAD_REQUEST;
    return build(status, ex.getMessage(), request);
  }

  static boolean lanzadaPorElDominio(Throwable ex) {
    StackTraceElement[] trace = ex.getStackTrace();
    if (trace.length == 0) {
      return false;
    }
    String origen = trace[0].getClassName();
    return origen.startsWith("com.lavadero.") && origen.contains(".domain.");
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
