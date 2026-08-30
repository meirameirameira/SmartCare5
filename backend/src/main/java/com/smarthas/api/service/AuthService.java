package com.smarthas.api.service;

import com.smarthas.api.domain.AppUser;
import com.smarthas.api.domain.Patient;
import com.smarthas.api.repository.AppUserRepository;
import com.smarthas.api.repository.PatientRepository;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.security.JwtService;
import com.smarthas.api.web.dto.AuthDtos;
import com.smarthas.api.web.error.BusinessRuleException;
import com.smarthas.api.web.error.ResourceNotFoundException;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Autenticacao e criacao de acessos. */
@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final AppUserRepository users;
    private final PatientRepository patients;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(AuthenticationManager authenticationManager, AppUserRepository users,
                       PatientRepository patients, PasswordEncoder passwordEncoder, JwtService jwtService) {
        this.authenticationManager = authenticationManager;
        this.users = users;
        this.patients = patients;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    /**
     * Valida as credenciais e emite o JWT.
     *
     * <p>A verificacao da senha e delegada ao {@code AuthenticationManager},
     * que usa BCrypt em tempo constante — evitando comparacao manual de hash.</p>
     */
    @Transactional(readOnly = true)
    public AuthDtos.TokenResponse login(AuthDtos.LoginRequest request) {
        Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(request.email(), request.password()));

        AppUserPrincipal principal = (AppUserPrincipal) authentication.getPrincipal();
        String token = jwtService.generateToken(principal);

        return new AuthDtos.TokenResponse(token, "Bearer", jwtService.getExpirationMinutes(), toUser(principal));
    }

    /** Cria um acesso de paciente, opcionalmente vinculado a um prontuario. */
    @Transactional
    public AuthDtos.UserResponse register(AuthDtos.RegisterRequest request) {
        if (users.existsByEmailIgnoreCase(request.email())) {
            throw new BusinessRuleException("Ja existe um acesso cadastrado com este e-mail.");
        }

        AppUser user = new AppUser(
                request.email().toLowerCase(),
                passwordEncoder.encode(request.password()),
                request.name(),
                AppUser.Role.PATIENT);

        if (request.patientId() != null) {
            Patient patient = patients.findById(request.patientId())
                    .orElseThrow(() -> new ResourceNotFoundException("Paciente", request.patientId()));
            user.setPatient(patient);
        }

        AppUser saved = users.save(user);
        return new AuthDtos.UserResponse(saved.getId(), saved.getEmail(), saved.getName(),
                saved.getRole().name(), saved.getPatient() == null ? null : saved.getPatient().getId());
    }

    public AuthDtos.UserResponse toUser(AppUserPrincipal principal) {
        return new AuthDtos.UserResponse(
                principal.getUserId(),
                principal.getUsername(),
                principal.getDisplayName(),
                principal.getRole().name(),
                principal.getPatientId());
    }
}
