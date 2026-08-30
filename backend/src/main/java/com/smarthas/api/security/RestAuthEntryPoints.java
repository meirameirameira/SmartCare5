package com.smarthas.api.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.security.web.AuthenticationEntryPoint;
import org.springframework.security.web.access.AccessDeniedHandler;

/**
 * Respostas 401/403 em JSON.
 *
 * <p>Sem isso o Spring devolveria uma pagina HTML de erro, que o cliente Dart
 * nao consegue desserializar.</p>
 */
public final class RestAuthEntryPoints {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    private RestAuthEntryPoints() {
    }

    public static AuthenticationEntryPoint unauthorized() {
        return (request, response, exception) -> write(response, HttpServletResponse.SC_UNAUTHORIZED,
                "Nao autenticado", "Envie o cabecalho Authorization: Bearer <token>.", request.getRequestURI());
    }

    public static AccessDeniedHandler forbidden() {
        return (request, response, exception) -> write(response, HttpServletResponse.SC_FORBIDDEN,
                "Acesso negado", "Seu perfil nao tem permissao para este recurso.", request.getRequestURI());
    }

    private static void write(HttpServletResponse response, int status, String error, String message, String path)
            throws IOException {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", status);
        body.put("error", error);
        body.put("message", message);
        body.put("path", path);

        response.setStatus(status);
        response.setContentType(MediaType.APPLICATION_JSON_VALUE);
        response.setCharacterEncoding("UTF-8");
        MAPPER.writeValue(response.getOutputStream(), body);
    }
}
