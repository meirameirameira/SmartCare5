package com.smarthas.api.config;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;
import java.util.List;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Documentacao OpenAPI 3 publicada em {@code /swagger-ui.html}.
 *
 * <p>Declara o esquema {@code bearerAuth} para que o Swagger UI permita colar o
 * token JWT e testar os endpoints protegidos direto do navegador.</p>
 */
@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI smartHasOpenApi() {
        final String securitySchemeName = "bearerAuth";

        return new OpenAPI()
                .info(new Info()
                        .title("Smart HAS / SmartCare 5.0 - API REST")
                        .version("5.0.0")
                        .description("""
                                API REST que fornece ao aplicativo Flutter os dados de monitoramento
                                de saude, alertas clinicos, entregas de medicamentos (AI Logistics
                                Extension) e teleconsulta.

                                Autenticacao: obtenha um token em POST /api/v1/auth/login e envie-o
                                no cabecalho "Authorization: Bearer {token}".

                                Credenciais de demonstracao:
                                - admin@smarthas.com / admin123 (ADMIN)
                                - enfermagem@smarthas.com / enfermagem123 (PROFESSIONAL)
                                - felipe@smarthas.com / paciente123 (PATIENT)
                                """)
                        .contact(new Contact().name("Equipe Smart HAS").email("contato@smarthas.com"))
                        .license(new License().name("Uso academico - FIAP")))
                .servers(List.of(new Server().url("/").description("Servidor atual")))
                .addSecurityItem(new SecurityRequirement().addList(securitySchemeName))
                .components(new Components().addSecuritySchemes(securitySchemeName,
                        new SecurityScheme()
                                .name(securitySchemeName)
                                .type(SecurityScheme.Type.HTTP)
                                .scheme("bearer")
                                .bearerFormat("JWT")
                                .description("Token JWT obtido em /api/v1/auth/login")));
    }
}
