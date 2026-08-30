package com.smarthas.api.security;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** Parametros de emissao e validacao do token JWT. */
@ConfigurationProperties(prefix = "smarthas.jwt")
public class JwtProperties {

    /** Segredo HMAC. Em producao deve vir da variavel SMARTHAS_JWT_SECRET. */
    private String secret;

    private String issuer = "smart-has-api";

    private long expirationMinutes = 480;

    public String getSecret() {
        return secret;
    }

    public void setSecret(String secret) {
        this.secret = secret;
    }

    public String getIssuer() {
        return issuer;
    }

    public void setIssuer(String issuer) {
        this.issuer = issuer;
    }

    public long getExpirationMinutes() {
        return expirationMinutes;
    }

    public void setExpirationMinutes(long expirationMinutes) {
        this.expirationMinutes = expirationMinutes;
    }
}
