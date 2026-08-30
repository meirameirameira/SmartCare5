package com.smarthas.api.web.error;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.ConstraintViolationException;
import java.time.Instant;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.converter.HttpMessageNotReadableException;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;

/**
 * Tratamento central de erros da API.
 *
 * <p>Todas as falhas saem no mesmo envelope JSON ({@code timestamp, status,
 * error, message, path} e, quando houver, {@code fieldErrors}), o que permite
 * ao app Flutter mapea-las para as suas {@code AppFailure} tipadas.</p>
 */
@RestControllerAdvice
public class ApiExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(ApiExceptionHandler.class);

    /** Erros de validacao de Bean Validation em @RequestBody. */
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex,
                                                                HttpServletRequest request) {
        List<Map<String, String>> fieldErrors = ex.getBindingResult().getFieldErrors().stream()
                .map(error -> Map.of(
                        "field", error.getField(),
                        "message", error.getDefaultMessage() == null ? "valor invalido" : error.getDefaultMessage()))
                .toList();

        Map<String, Object> body = envelope(HttpStatus.BAD_REQUEST, "Dados invalidos",
                "Corrija os campos indicados e tente novamente.", request);
        body.put("fieldErrors", fieldErrors);
        return ResponseEntity.badRequest().body(body);
    }

    @ExceptionHandler(ConstraintViolationException.class)
    public ResponseEntity<Map<String, Object>> handleConstraint(ConstraintViolationException ex,
                                                                HttpServletRequest request) {
        return ResponseEntity.badRequest().body(
                envelope(HttpStatus.BAD_REQUEST, "Dados invalidos", ex.getMessage(), request));
    }

    @ExceptionHandler(HttpMessageNotReadableException.class)
    public ResponseEntity<Map<String, Object>> handleUnreadable(HttpMessageNotReadableException ex,
                                                                HttpServletRequest request) {
        return ResponseEntity.badRequest().body(envelope(HttpStatus.BAD_REQUEST, "Corpo invalido",
                "Nao foi possivel interpretar o JSON enviado.", request));
    }

    @ExceptionHandler(MethodArgumentTypeMismatchException.class)
    public ResponseEntity<Map<String, Object>> handleTypeMismatch(MethodArgumentTypeMismatchException ex,
                                                                  HttpServletRequest request) {
        return ResponseEntity.badRequest().body(envelope(HttpStatus.BAD_REQUEST, "Parametro invalido",
                "O parametro '" + ex.getName() + "' recebeu um valor invalido.", request));
    }

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, Object>> handleNotFound(ResourceNotFoundException ex,
                                                              HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(envelope(HttpStatus.NOT_FOUND, "Recurso nao encontrado", ex.getMessage(), request));
    }

    @ExceptionHandler(BusinessRuleException.class)
    public ResponseEntity<Map<String, Object>> handleBusinessRule(BusinessRuleException ex,
                                                                  HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY)
                .body(envelope(HttpStatus.UNPROCESSABLE_ENTITY, "Regra de negocio", ex.getMessage(), request));
    }

    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, Object>> handleBadCredentials(BadCredentialsException ex,
                                                                    HttpServletRequest request) {
        // Mensagem generica: nao informa se o e-mail existe.
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(envelope(HttpStatus.UNAUTHORIZED, "Credenciais invalidas",
                        "E-mail ou senha incorretos.", request));
    }

    @ExceptionHandler(AccessDeniedException.class)
    public ResponseEntity<Map<String, Object>> handleAccessDenied(AccessDeniedException ex,
                                                                  HttpServletRequest request) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(envelope(HttpStatus.FORBIDDEN, "Acesso negado",
                        "Seu perfil nao tem permissao para este recurso.", request));
    }

    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, Object>> handleDataIntegrity(DataIntegrityViolationException ex,
                                                                   HttpServletRequest request) {
        log.warn("Violacao de integridade em {}: {}", request.getRequestURI(), ex.getMostSpecificCause().getMessage());
        return ResponseEntity.status(HttpStatus.CONFLICT)
                .body(envelope(HttpStatus.CONFLICT, "Conflito de dados",
                        "O registro viola uma restricao de unicidade ou integridade.", request));
    }

    /** Rede de seguranca: nada de stack trace vazando para o cliente. */
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, Object>> handleUnexpected(Exception ex, HttpServletRequest request) {
        log.error("Erro nao tratado em {}", request.getRequestURI(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(envelope(HttpStatus.INTERNAL_SERVER_ERROR, "Erro interno",
                        "Ocorreu um erro inesperado. Tente novamente em instantes.", request));
    }

    private Map<String, Object> envelope(HttpStatus status, String error, String message,
                                         HttpServletRequest request) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("timestamp", Instant.now().toString());
        body.put("status", status.value());
        body.put("error", error);
        body.put("message", message);
        body.put("path", request.getRequestURI());
        return body;
    }
}
