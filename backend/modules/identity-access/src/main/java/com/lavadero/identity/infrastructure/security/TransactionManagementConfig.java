package com.lavadero.identity.infrastructure.security;

import org.springframework.context.annotation.Configuration;
import org.springframework.transaction.annotation.EnableTransactionManagement;

/**
 * IMPORTANTE para la corrección de {@link TenantAwareTransactionAspect}: por defecto, el advisor de
 * {@code @Transactional} de Spring Boot se registra con {@code Ordered.LOWEST_PRECEDENCE} (la
 * mínima prioridad posible), lo que lo convierte en la capa MÁS INTERNA de cualquier cadena de AOP
 * — ningún otro aspecto podría, con su propio {@code @Order}, ejecutarse "más adentro" que él (no
 * hay un número más alto que {@code Integer.MAX_VALUE}).
 *
 * <p>Para que {@code TenantAwareTransactionAspect} pueda ejecutarse DESPUÉS de que la transacción
 * ya inició (que es el requisito: `SET LOCAL` solo tiene efecto dentro de una transacción activa),
 * este bean fija explícitamente el advisor transaccional en el order {@code 100}, y el aspecto usa
 * {@code @Order(101)} — mayor valor de order = menor precedencia = capa más interna = se ejecuta
 * DESPUÉS de que el advisor transaccional (order 100) ya abrió la transacción. Sin esto, el orden
 * relativo entre dos aspectos con la misma precedencia por defecto sería indefinido, arriesgando
 * ejecutar `SET LOCAL` fuera de transacción (sin efecto real, ver comentario en la política RLS).
 */
@Configuration
@EnableTransactionManagement(order = 100)
public class TransactionManagementConfig {}
