package com.lavadero.identity.infrastructure.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ReadListener;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletInputStream;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletRequestWrapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import org.springframework.web.filter.OncePerRequestFilter;

/**
 * Tope de tamaño del cuerpo para endpoints públicos que reciben un payload arbitrario (hoy, el
 * webhook de Wompi: sin JWT, cualquiera puede llamarlo). Sin esto, {@code @RequestBody String}
 * cargaría en memoria lo que mande el cliente.
 *
 * <p>Lee como mucho {@code limite + 1} bytes: si hay más, responde 413 sin tocar el controlador; si
 * no, re-entrega el cuerpo ya leído. Funciona igual con {@code Content-Length} que con cuerpo
 * chunked (el header solo sirve para cortar antes).
 */
public class LimiteCuerpoFilter extends OncePerRequestFilter {

  static final Map<String, Integer> LIMITES_BYTES =
      Map.of("/api/v1/pagos/webhook/wompi", 64 * 1024);

  @Override
  protected void doFilterInternal(
      HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
      throws ServletException, IOException {
    Integer limite = LIMITES_BYTES.get(request.getRequestURI());
    if (limite == null) {
      filterChain.doFilter(request, response);
      return;
    }
    if (request.getContentLengthLong() > limite) {
      rechazar(response);
      return;
    }
    byte[] cuerpo = request.getInputStream().readNBytes(limite + 1);
    if (cuerpo.length > limite) {
      rechazar(response);
      return;
    }
    filterChain.doFilter(new CuerpoLeido(request, cuerpo), response);
  }

  private static void rechazar(HttpServletResponse response) throws IOException {
    response.setStatus(HttpServletResponse.SC_REQUEST_ENTITY_TOO_LARGE);
    response.setContentType("application/json");
    response
        .getWriter()
        .write(
            "{\"error\":\"payload_too_large\",\"message\":\"El cuerpo excede el tamaño permitido\"}");
  }

  /** Request cuyo cuerpo ya se leyó (acotado) y se re-sirve desde memoria. */
  private static final class CuerpoLeido extends HttpServletRequestWrapper {
    private final byte[] cuerpo;

    CuerpoLeido(HttpServletRequest request, byte[] cuerpo) {
      super(request);
      this.cuerpo = cuerpo;
    }

    @Override
    public ServletInputStream getInputStream() {
      InputStream origen = new ByteArrayInputStream(cuerpo);
      return new ServletInputStream() {
        @Override
        public int read() throws IOException {
          return origen.read();
        }

        @Override
        public int read(byte[] b, int off, int len) throws IOException {
          return origen.read(b, off, len);
        }

        @Override
        public boolean isFinished() {
          try {
            return origen.available() == 0;
          } catch (IOException e) {
            return true;
          }
        }

        @Override
        public boolean isReady() {
          return true;
        }

        @Override
        public void setReadListener(ReadListener readListener) {
          throw new UnsupportedOperationException("Lectura asíncrona no soportada");
        }
      };
    }

    @Override
    public BufferedReader getReader() {
      String encoding = getCharacterEncoding();
      Charset charset = encoding == null ? StandardCharsets.UTF_8 : Charset.forName(encoding);
      return new BufferedReader(new InputStreamReader(getInputStream(), charset));
    }

    @Override
    public int getContentLength() {
      return cuerpo.length;
    }

    @Override
    public long getContentLengthLong() {
      return cuerpo.length;
    }
  }
}
