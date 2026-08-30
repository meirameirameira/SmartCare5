plugins {
    java
    id("org.springframework.boot") version "3.5.6"
    id("io.spring.dependency-management") version "1.1.7"
}

group = "com.smarthas"
version = "5.0.0"
description = "Smart HAS / SmartCare 5.0 - API REST"

java {
    toolchain {
        // O bytecode alvo continua sendo Java 21 mesmo que o JDK local seja mais novo.
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

repositories {
    mavenCentral()
}

extra["springdocVersion"] = "2.8.9"
extra["jjwtVersion"] = "0.12.6"

dependencies {
    // Web + Thymeleaf (Spring MVC server-side rendering do painel administrativo)
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-thymeleaf")

    // Persistencia e validacao
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-validation")

    // Seguranca (JWT stateless para o app mobile)
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("io.jsonwebtoken:jjwt-api:${property("jjwtVersion")}")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:${property("jjwtVersion")}")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:${property("jjwtVersion")}")

    // Documentacao OpenAPI / Swagger UI
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:${property("springdocVersion")}")

    // Observabilidade
    implementation("org.springframework.boot:spring-boot-starter-actuator")

    // Bancos de dados: H2 em desenvolvimento, PostgreSQL em producao
    runtimeOnly("com.h2database:h2")
    runtimeOnly("org.postgresql:postgresql")

    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
}

tasks.withType<Test> {
    useJUnitPlatform()
    systemProperty("spring.profiles.active", "test")
}
