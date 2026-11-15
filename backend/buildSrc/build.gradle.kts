plugins {
    `kotlin-dsl`
}

repositories {
    gradlePluginPortal()
    mavenCentral()
}

dependencies {
    // Plugins usados dentro de los convention plugins precompilados.
    implementation("org.springframework.boot:spring-boot-gradle-plugin:4.1.2")
    implementation("io.spring.gradle:dependency-management-plugin:1.1.7")
    implementation("com.diffplug.spotless:spotless-plugin-gradle:8.11.0")
}
