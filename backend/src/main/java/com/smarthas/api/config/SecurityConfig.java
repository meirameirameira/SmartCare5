package com.smarthas.api.config;

import com.smarthas.api.security.JwtAuthenticationFilter;
import com.smarthas.api.security.RestAuthEntryPoints;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.config.annotation.authentication.configuration.AuthenticationConfiguration;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Politica de seguranca da API.
 *
 * <p>Decisoes principais:</p>
 * <ul>
 *   <li><b>Stateless com JWT</b>: o app mobile nao mantem sessao no servidor;
 *       cada requisicao carrega o token. Por isso CSRF fica desabilitado apenas
 *       nas rotas {@code /api/**} (nao ha cookie de sessao para ser forjado).</li>
 *   <li><b>BCrypt</b> para as senhas, com fator de custo 10.</li>
 *   <li><b>Autorizacao por papel</b>: escrita administrativa exige
 *       PROFESSIONAL ou ADMIN; o paciente so le o proprio prontuario (validado
 *       tambem no servico, via {@code @PreAuthorize} e checagem de posse).</li>
 *   <li><b>CORS restrito</b> as origens declaradas em configuracao.</li>
 * </ul>
 */
@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final CorsProperties corsProperties;

    public SecurityConfig(JwtAuthenticationFilter jwtAuthenticationFilter, CorsProperties corsProperties) {
        this.jwtAuthenticationFilter = jwtAuthenticationFilter;
        this.corsProperties = corsProperties;
    }

    @Bean
    public PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    public AuthenticationManager authenticationManager(AuthenticationConfiguration configuration) throws Exception {
        return configuration.getAuthenticationManager();
    }

    @Bean
    public CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(corsProperties.getAllowedOrigins());
        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("Authorization", "Content-Type", "Accept"));
        configuration.setExposedHeaders(List.of("Authorization"));
        configuration.setMaxAge(3600L);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .csrf(csrf -> csrf.ignoringRequestMatchers("/api/**", "/h2-console/**"))
                .headers(headers -> headers.frameOptions(frame -> frame.sameOrigin()))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(handling -> handling
                        .authenticationEntryPoint(RestAuthEntryPoints.unauthorized())
                        .accessDeniedHandler(RestAuthEntryPoints.forbidden()))
                .authorizeHttpRequests(auth -> auth
                        // Autenticacao e documentacao sao publicas.
                        .requestMatchers("/api/v1/auth/login", "/api/v1/auth/register").permitAll()
                        .requestMatchers("/swagger-ui.html", "/swagger-ui/**", "/v3/api-docs/**").permitAll()
                        .requestMatchers("/actuator/health", "/actuator/info").permitAll()
                        // Painel Thymeleaf e recursos estaticos do painel.
                        .requestMatchers("/", "/painel", "/css/**", "/h2-console/**").permitAll()
                        // Escrita administrativa restrita a profissionais. O caminho e exato:
                        // o proprio paciente (e o gateway do wearable) precisa poder enviar
                        // leituras em POST /api/v1/patients/{id}/vitals.
                        .requestMatchers(HttpMethod.POST, "/api/v1/patients").hasAnyRole("PROFESSIONAL", "ADMIN")
                        .requestMatchers(HttpMethod.PUT, "/api/v1/**").hasAnyRole("PROFESSIONAL", "ADMIN")
                        .requestMatchers(HttpMethod.DELETE, "/api/v1/**").hasRole("ADMIN")
                        .requestMatchers("/api/v1/analytics/overview").hasAnyRole("PROFESSIONAL", "ADMIN")
                        .anyRequest().authenticated())
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .httpBasic(AbstractHttpConfigurer::disable)
                .formLogin(AbstractHttpConfigurer::disable);

        return http.build();
    }
}
