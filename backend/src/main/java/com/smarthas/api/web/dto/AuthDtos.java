package com.smarthas.api.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Contratos de entrada e saida do fluxo de autenticacao. */
public final class AuthDtos {

    private AuthDtos() {
    }

    @Schema(description = "Credenciais de acesso")
    public record LoginRequest(
            @NotBlank(message = "Informe o e-mail")
            @Email(message = "E-mail invalido")
            @Schema(example = "felipe@smarthas.com")
            String email,

            @NotBlank(message = "Informe a senha")
            @Schema(example = "paciente123")
            String password) {
    }

    @Schema(description = "Dados para criacao de um novo acesso de paciente")
    public record RegisterRequest(
            @NotBlank(message = "Informe o e-mail")
            @Email(message = "E-mail invalido")
            String email,

            @NotBlank(message = "Informe a senha")
            @Size(min = 8, message = "A senha deve ter ao menos 8 caracteres")
            String password,

            @NotBlank(message = "Informe o nome")
            String name,

            @Schema(description = "Prontuario a vincular ao novo usuario", nullable = true)
            Long patientId) {
    }

    @Schema(description = "Token de acesso e dados do usuario autenticado")
    public record TokenResponse(
            String accessToken,
            String tokenType,
            long expiresInMinutes,
            UserResponse user) {
    }

    @Schema(description = "Usuario autenticado")
    public record UserResponse(
            Long id,
            String email,
            String name,
            String role,
            Long patientId) {
    }
}
