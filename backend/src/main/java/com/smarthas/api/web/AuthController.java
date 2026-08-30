package com.smarthas.api.web;

import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.service.AuthService;
import com.smarthas.api.web.dto.AuthDtos;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Autenticacao: emissao de token JWT e criacao de acessos. */
@RestController
@RequestMapping("/api/v1/auth")
@Tag(name = "Autenticacao", description = "Login, cadastro e dados do usuario autenticado")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    @SecurityRequirements
    @Operation(summary = "Autentica e devolve o token JWT")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Autenticado"),
            @ApiResponse(responseCode = "400", description = "Dados invalidos"),
            @ApiResponse(responseCode = "401", description = "Credenciais invalidas")
    })
    public AuthDtos.TokenResponse login(@Valid @RequestBody AuthDtos.LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/register")
    @SecurityRequirements
    @Operation(summary = "Cria um acesso de paciente")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Acesso criado"),
            @ApiResponse(responseCode = "422", description = "E-mail ja cadastrado")
    })
    public ResponseEntity<AuthDtos.UserResponse> register(@Valid @RequestBody AuthDtos.RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.register(request));
    }

    @GetMapping("/me")
    @SecurityRequirement(name = "bearerAuth")
    @Operation(summary = "Dados do usuario autenticado")
    public AuthDtos.UserResponse me(@AuthenticationPrincipal AppUserPrincipal principal) {
        return authService.toUser(principal);
    }
}
