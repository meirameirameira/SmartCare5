package com.smarthas.api.repository;

import com.smarthas.api.domain.AlertType;
import com.smarthas.api.domain.HealthAlert;
import java.util.List;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface HealthAlertRepository extends JpaRepository<HealthAlert, Long> {

    List<HealthAlert> findByPatientIdOrderByCreatedAtDesc(Long patientId, Pageable pageable);

    List<HealthAlert> findByPatientIdAndAcknowledgedFalseOrderByCreatedAtDesc(Long patientId);

    long countByAcknowledgedFalse();

    long countByAcknowledgedFalseAndType(AlertType type);

    /** Evita duplicar o mesmo alerta automatico enquanto ele nao for tratado. */
    boolean existsByPatientIdAndMetricAndAcknowledgedFalse(Long patientId, String metric);
}
