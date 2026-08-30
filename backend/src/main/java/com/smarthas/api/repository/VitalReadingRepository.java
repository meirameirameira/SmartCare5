package com.smarthas.api.repository;

import com.smarthas.api.domain.VitalReading;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface VitalReadingRepository extends JpaRepository<VitalReading, Long> {

    /** Ultima leitura conhecida do paciente (usada no dashboard e no score). */
    Optional<VitalReading> findFirstByPatientIdOrderByMeasuredAtDesc(Long patientId);

    /** Historico paginado, mais recente primeiro. */
    List<VitalReading> findByPatientIdOrderByMeasuredAtDesc(Long patientId, Pageable pageable);

    /** Serie temporal do periodo, em ordem cronologica, para os graficos. */
    List<VitalReading> findByPatientIdAndMeasuredAtAfterOrderByMeasuredAtAsc(Long patientId, Instant since);

    long countByPatientId(Long patientId);
}
