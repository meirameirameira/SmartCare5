package com.smarthas.api.security;

import com.smarthas.api.domain.AppUser;
import java.util.Collection;
import java.util.List;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

/**
 * Usuario autenticado exposto ao contexto do Spring Security.
 *
 * <p>Carrega o id do paciente vinculado, o que permite verificar posse do
 * recurso ("este paciente e o meu?") sem uma consulta extra ao banco.</p>
 */
public class AppUserPrincipal implements UserDetails {

    private final Long userId;
    private final String email;
    private final String passwordHash;
    private final String displayName;
    private final AppUser.Role role;
    private final Long patientId;
    private final boolean enabled;

    public AppUserPrincipal(AppUser user) {
        this.userId = user.getId();
        this.email = user.getEmail();
        this.passwordHash = user.getPasswordHash();
        this.displayName = user.getName();
        this.role = user.getRole();
        this.patientId = user.getPatient() == null ? null : user.getPatient().getId();
        this.enabled = user.isEnabled();
    }

    public Long getUserId() {
        return userId;
    }

    public String getDisplayName() {
        return displayName;
    }

    public AppUser.Role getRole() {
        return role;
    }

    public Long getPatientId() {
        return patientId;
    }

    /** Papeis com visao completa da base de pacientes. */
    public boolean isStaff() {
        return role == AppUser.Role.PROFESSIONAL || role == AppUser.Role.ADMIN;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role.name()));
    }

    @Override
    public String getPassword() {
        return passwordHash;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return enabled;
    }
}
