package com.lavadero.identity.infrastructure.security;

import java.util.HashMap;
import java.util.Map;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.argon2.Argon2PasswordEncoder;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.DelegatingPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;

/**
 * Argon2id como algoritmo de hashing de contraseñas (ganador del Password Hashing Competition,
 * resistente a ataques con GPU/ASIC, recomendado por OWASP por delante de bcrypt para nuevos
 * sistemas). Se envuelve en un {@link DelegatingPasswordEncoder} (prefijo {@code {argon2}}
 * almacenado junto al hash) para poder migrar de algoritmo en el futuro sin invalidar las
 * contraseñas ya existentes: el delegating encoder sabe verificar hashes de algoritmos antiguos
 * aunque el "encode" por defecto sea siempre el más reciente.
 */
@Configuration
public class PasswordEncoderConfig {

  @Bean
  public PasswordEncoder passwordEncoder() {
    Map<String, PasswordEncoder> encoders = new HashMap<>();
    Argon2PasswordEncoder argon2 = Argon2PasswordEncoder.defaultsForSpringSecurity_v5_8();
    encoders.put("argon2", argon2);
    encoders.put("bcrypt", new BCryptPasswordEncoder());

    DelegatingPasswordEncoder delegatingPasswordEncoder =
        new DelegatingPasswordEncoder("argon2", encoders);
    delegatingPasswordEncoder.setDefaultPasswordEncoderForMatches(argon2);
    return delegatingPasswordEncoder;
  }
}
