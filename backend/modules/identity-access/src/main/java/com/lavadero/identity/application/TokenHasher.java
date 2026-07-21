package com.lavadero.identity.application;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Base64;

/**
 * Hashea refresh tokens antes de persistirlos. Nunca se guarda el token en claro (ver columna
 * {@code token_hash} en V2__identity_access.sql): si la base de datos se filtra, los refresh tokens
 * en claro no son recuperables. SHA-256 es suficiente aquí (a diferencia de passwords, un refresh
 * token ya es un secreto aleatorio de alta entropía, no necesita Argon2/bcrypt).
 */
public final class TokenHasher {

  private TokenHasher() {}

  public static String sha256(String valorEnClaro) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] hash = digest.digest(valorEnClaro.getBytes(StandardCharsets.UTF_8));
      return Base64.getEncoder().encodeToString(hash);
    } catch (NoSuchAlgorithmException e) {
      throw new IllegalStateException("SHA-256 no disponible en esta JVM", e);
    }
  }
}
