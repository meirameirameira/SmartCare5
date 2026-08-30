package com.smarthas.api.config;

import java.util.List;
import org.springframework.boot.context.properties.ConfigurationProperties;

/**
 * Origens autorizadas a consumir a API (app Flutter Web e painel Angular).
 *
 * <p>Configuravel por ambiente em {@code application.yml} / variaveis de
 * ambiente, sem recompilar a aplicacao.</p>
 */
@ConfigurationProperties(prefix = "smarthas.cors")
public class CorsProperties {

    private List<String> allowedOrigins = List.of("http://localhost:4200");

    public List<String> getAllowedOrigins() {
        return allowedOrigins;
    }

    public void setAllowedOrigins(List<String> allowedOrigins) {
        this.allowedOrigins = allowedOrigins;
    }
}
