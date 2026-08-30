package com.smarthas.api.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import java.util.Map;
import javax.crypto.SecretKey;
import org.springframework.stereotype.Service;

/** Emissao e validacao dos tokens JWT (HMAC-SHA256). */
@Service
public class JwtService {

    private final JwtProperties properties;
    private final SecretKey key;

    public JwtService(JwtProperties properties) {
        this.properties = properties;
        String secret = properties.getSecret();
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalStateException(
                    "smarthas.jwt.secret deve ter no minimo 32 caracteres. "
                            + "Defina a variavel de ambiente SMARTHAS_JWT_SECRET.");
        }
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
    }

    /** Gera o token com o papel e o paciente vinculado nas claims. */
    public String generateToken(AppUserPrincipal principal) {
        Instant now = Instant.now();
        Instant expiresAt = now.plus(Duration.ofMinutes(properties.getExpirationMinutes()));

        return Jwts.builder()
                .subject(principal.getUsername())
                .issuer(properties.getIssuer())
                .issuedAt(Date.from(now))
                .expiration(Date.from(expiresAt))
                .claims(Map.of(
                        "uid", principal.getUserId(),
                        "role", principal.getRole().name(),
                        "name", principal.getDisplayName(),
                        "patientId", principal.getPatientId() == null ? -1L : principal.getPatientId()))
                .signWith(key)
                .compact();
    }

    /** Extrai o e-mail do token, ou {@code null} se ele for invalido/expirado. */
    public String extractSubject(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(key)
                    .requireIssuer(properties.getIssuer())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();
            return claims.getSubject();
        } catch (JwtException | IllegalArgumentException e) {
            return null;
        }
    }

    public long getExpirationMinutes() {
        return properties.getExpirationMinutes();
    }
}
