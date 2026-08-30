package com.smarthas.api.repository;

import com.smarthas.api.domain.AppUser;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.EntityGraph;

public interface AppUserRepository extends JpaRepository<AppUser, Long> {

    /**
     * Carrega o usuario junto do paciente vinculado em uma unica consulta,
     * evitando o N+1 no filtro de autenticacao (executado a cada requisicao).
     */
    @EntityGraph(attributePaths = "patient")
    Optional<AppUser> findByEmailIgnoreCase(String email);

    boolean existsByEmailIgnoreCase(String email);
}
