package com.smarthas.api.repository;

import com.smarthas.api.domain.Patient;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PatientRepository extends JpaRepository<Patient, Long> {

    /** Busca por nome parcial, usada pelo filtro do painel administrativo. */
    @Query("select p from Patient p where lower(p.name) like lower(concat('%', :term, '%'))")
    List<Patient> searchByName(@Param("term") String term, Pageable pageable);

    List<Patient> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
