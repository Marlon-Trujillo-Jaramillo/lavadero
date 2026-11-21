rootProject.name = "lavadero-backend"

// Módulo BOM (alineación de versiones)
include("platform")

// Kernel compartido entre todos los bounded contexts
include("shared-kernel")

// Eventos de dominio compartidos entre módulos de negocio
include("contracts")

include("messaging")

// Módulos de negocio (bounded contexts como módulos físicos de Gradle)
include("modules:tenant-management")
include("modules:identity-access")
include("modules:catalog")
include("modules:scheduling")
include("modules:inventory")

// Tests de arquitectura (ArchUnit) que escanean todos los módulos anteriores
include("architecture-tests")

// Módulo ejecutable (Spring Boot)
include("bootstrap")
