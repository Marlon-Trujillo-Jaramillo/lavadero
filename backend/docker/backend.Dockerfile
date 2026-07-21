# syntax=docker/dockerfile:1
#
# Build multi-stage del monolito modular Lavadero.
# Contexto de build esperado: la raíz de `backend/` (para que el gradlew,
# los settings.gradle.kts y todos los módulos estén disponibles), p. ej.:
#   docker build -f docker/backend.Dockerfile -t lavadero-backend:local .
# (ejecutado desde `backend/`).

# ---- Etapa 1: build con Gradle ----
FROM eclipse-temurin:21-jdk-jammy AS build
WORKDIR /workspace

# Copiamos primero solo lo necesario para resolver dependencias y aprovechar
# la cache de capas de Docker cuando el código fuente cambia pero las
# dependencias no.
COPY gradlew gradlew.bat gradle.properties settings.gradle.kts build.gradle.kts ./
COPY gradle ./gradle
COPY buildSrc ./buildSrc
COPY platform ./platform
COPY shared-kernel ./shared-kernel
COPY contracts ./contracts
COPY modules ./modules
COPY architecture-tests ./architecture-tests
COPY bootstrap ./bootstrap

RUN chmod +x gradlew && ./gradlew :bootstrap:bootJar --no-daemon -x test

# ---- Etapa 2: runtime mínimo ----
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

RUN useradd --system --create-home --shell /usr/sbin/nologin lavadero

COPY --from=build /workspace/bootstrap/build/libs/*.jar app.jar
RUN chown lavadero:lavadero app.jar

USER lavadero
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
