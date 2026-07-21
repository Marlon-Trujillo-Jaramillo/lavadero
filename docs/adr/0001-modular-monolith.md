# ADR 0001: Monolito modular con módulos Gradle en vez de microservicios

## Estado

Aceptado.

## Contexto

Lavadero es un SaaS multi-tenant para lavaderos de autos pequeños y
medianos, construido y operado por un único desarrollador freelance. Además
de ser un producto comercial real, es una pieza de portafolio: debe
demostrar buenas prácticas de diseño (DDD, Clean Architecture,
multi-tenancy segura) sin incurrir en la complejidad operativa de una
arquitectura que el propio equipo (una persona) no puede sostener.

Restricciones concretas de este contexto:

- Un solo desarrollador escribe, despliega y opera el sistema. No hay
  equipo de plataforma/SRE dedicado.
- El número esperado de tenants e intensidad de tráfico en el horizonte
  inicial (fase de adquisición de los primeros clientes) es bajo: decenas
  de lavaderos, no miles.
- El presupuesto de infraestructura debe mantenerse mínimo (idealmente un
  solo servidor/instancia gestionable).
- El producto necesita evolucionar rápido (nuevos bounded contexts:
  agenda/scheduling, facturación, notificaciones) sin que cada nueva
  funcionalidad implique estrenar un servicio, un pipeline de despliegue y
  una base de datos nuevos.
- Aun así, el código debe quedar organizado de forma que, si el negocio
  creciera lo suficiente como para justificarlo, extraer un bounded context
  a un servicio independiente sea un cambio localizado, no una reescritura.

Las dos alternativas evaluadas fueron:

1. **Microservicios** desde el día uno: un servicio por bounded context
   (tenant-management, identity-access, scheduling, billing, ...), cada uno
   con su propia base de datos, su propio pipeline CI/CD y comunicándose
   por HTTP/mensajería.
2. **Monolito modular**: un único proceso desplegable, pero con los
   bounded contexts separados físicamente como módulos Gradle
   independientes, cada uno con capas internas de Clean Architecture
   (`domain/application/infrastructure/interfaces`) y fronteras de
   dependencia explícitas y verificadas (ArchUnit).

## Decisión

Se adopta el **monolito modular** (opción 2): un solo proceso Spring Boot
ejecutable (`backend/bootstrap`), compuesto por módulos Gradle que
representan bounded contexts DDD (`tenant-management`, `identity-access`,
y los que sigan), más módulos de soporte (`shared-kernel`, `contracts`,
`platform`, `architecture-tests`).

Reglas que hacen que este monolito no degenere en un "big ball of mud":

- **Multi-tenancy con dos capas de aislamiento**: Shared DB + columna
  `tenant_id` + Row Level Security de Postgres (la barrera real,
  infranqueable aunque la aplicación tenga un bug), reforzada con un filtro
  de Hibernate a nivel de sesión (defensa en profundidad, no la única
  barrera).
- **Fronteras de módulo = fronteras de compilación**: cada bounded context
  es su propio módulo Gradle; las dependencias entre ellos son explícitas
  en cada `build.gradle.kts` (p. ej. `identity-access` depende de
  `tenant-management` para resolver tenants por slug, nunca al revés) y el
  compilador las hace cumplir, no son solo una convención de paquetes.
- **Clean Architecture dentro de cada módulo**: `domain` no conoce Spring
  ni JPA; `application` no conoce `infrastructure` ni `interfaces`. Estas
  reglas están además verificadas automáticamente por `architecture-tests`
  (ArchUnit) contra el bytecode real, no solo documentadas en comentarios.
- **Eventos de dominio vía `contracts`**: la comunicación entre bounded
  contexts que no dependen directamente entre sí ocurre publicando eventos
  de dominio versionados en un módulo compartido, el mismo mecanismo que se
  usaría entre microservicios (solo que in-process), lo que deja la puerta
  abierta a extraer un contexto sin rediseñar cómo se comunican.

## Consecuencias

**Positivas:**

- Un solo despliegue, una sola base de datos, un solo pipeline de CI/CD:
  operable por una persona.
- Transacciones ACID reales entre agregados de distintos módulos cuando se
  necesitan (p. ej. onboarding de un tenant: crear `Tenant` + `Sucursal`
  principal en la misma transacción), sin sagas ni compensación
  distribuida.
- Sin latencia de red entre bounded contexts ni necesidad de un
  service mesh, tracing distribuido o un bus de mensajería para el tráfico
  normal entre módulos.
- El código demuestra las mismas disciplinas de diseño (límites de
  contexto, Clean Architecture, eventos de dominio) que un sistema de
  microservicios, útil como pieza de portafolio, sin el costo operativo.
- Camino de escape real: si en el futuro un bounded context (p. ej.
  `billing`, por volumen o por requisitos de aislamiento) justifica
  extraerse, ya vive en su propio módulo con dependencias explícitas y sin
  acceso directo a las tablas de otros contextos (solo a través de sus
  repositorios/eventos), lo que reduce (no elimina) el trabajo de
  extracción.

**Negativas / trade-offs aceptados:**

- Escalado independiente por bounded context no es posible: todo el
  proceso escala junto. Aceptable en el volumen de tráfico esperado.
- Un fallo o un despliegue afecta a todo el sistema a la vez (no hay
  aislamiento de fallos entre módulos a nivel de proceso). Mitigado por
  mantener el proceso simple y con buena cobertura de tests.
- Disciplina de equipo: nada impide *en tiempo de ejecución* que un módulo
  importe una clase interna de otro si alguien decide ignorar las
  convenciones; la única barrera real es `architecture-tests` (ArchUnit) y
  la revisión de código. Se acepta este riesgo porque el equipo es de una
  persona y el ArchUnit gate corre en cada build.
- Migrar a microservicios más adelante seguiría requiriendo trabajo real
  (separar bases de datos, introducir comunicación asíncrona/eventual en
  vez de transacciones ACID, versionar contratos entre servicios): esta
  decisión reduce ese costo futuro, no lo elimina.
