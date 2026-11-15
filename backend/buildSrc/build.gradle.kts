plugins {
    `kotlin-dsl`
}

repositories {
    gradlePluginPortal()
    mavenCentral()
}

dependencies {
    // Plugins usados dentro de los convention plugins precompilados.
    implementation("org.springframework.boot:spring-boot-gradle-plugin:3.5.16")
    implementation("io.spring.gradle:dependency-management-plugin:1.1.7")
    implementation("com.diffplug.spotless:spotless-plugin-gradle:6.25.0")
}
