package com.smarthas.api;

import com.smarthas.api.config.CorsProperties;
import com.smarthas.api.security.JwtProperties;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;

/**
 * Ponto de entrada da API REST do Smart HAS / SmartCare 5.0.
 *
 * <p>O servico expoe em JSON os dados consumidos pelo app Flutter (sinais vitais,
 * alertas, entregas de medicamentos e teleconsulta) e renderiza, via Thymeleaf,
 * um painel administrativo server-side para a equipe de operacao.</p>
 */
@SpringBootApplication
@EnableConfigurationProperties({JwtProperties.class, CorsProperties.class})
public class SmartHasApiApplication {

    public static void main(String[] args) {
        SpringApplication.run(SmartHasApiApplication.class, args);
    }
}
