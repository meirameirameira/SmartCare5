package com.smarthas.api.repository;

import com.smarthas.api.domain.Doctor;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DoctorRepository extends JpaRepository<Doctor, Long> {

    List<Doctor> findByAvailableTrueOrderByNameAsc();

    List<Doctor> findBySpecialtyIgnoreCaseOrderByNameAsc(String specialty);

    Optional<Doctor> findByCrm(String crm);
}
