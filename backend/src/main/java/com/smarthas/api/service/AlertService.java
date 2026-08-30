package com.smarthas.api.service;

import com.smarthas.api.domain.AlertType;
import com.smarthas.api.domain.HealthAlert;
import com.smarthas.api.domain.Patient;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.repository.HealthAlertRepository;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.web.dto.AlertDtos;
import com.smarthas.api.web.dto.VitalDtos;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Consulta, criacao manual e geracao automatica de alertas clinicos. */
@Service
public class AlertService {

    private final HealthAlertRepository alerts;
    private final PatientService patientService;
    private final HealthScoreCalculator scoreCalculator;

    public AlertService(HealthAlertRepository alerts, PatientService patientService,
                        HealthScoreCalculator scoreCalculator) {
        this.alerts = alerts;
        this.patientService = patientService;
        this.scoreCalculator = scoreCalculator;
    }

    @Transactional(readOnly = true)
    public List<AlertDtos.AlertResponse> listByPatient(Long patientId, boolean onlyOpen, int limit,
                                                       AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);

        List<HealthAlert> found = onlyOpen
                ? alerts.findByPatientIdAndAcknowledgedFalseOrderByCreatedAtDesc(patientId)
                : alerts.findByPatientIdOrderByCreatedAtDesc(patientId,
                        PageRequest.of(0, Math.min(Math.max(limit, 1), 100)));

        return found.stream().map(AlertDtos.AlertResponse::from).toList();
    }

    @Transactional
    public AlertDtos.AlertResponse create(Long patientId, AlertDtos.AlertRequest request,
                                          AppUserPrincipal principal) {
        Patient patient = patientService.requireAccessible(patientId, principal);
        HealthAlert alert = new HealthAlert(patient, request.type(), request.title(),
                request.description(), request.metric());
        return AlertDtos.AlertResponse.from(alerts.save(alert));
    }

    @Transactional
    public AlertDtos.AlertResponse acknowledge(Long alertId, AppUserPrincipal principal) {
        HealthAlert alert = alerts.findById(alertId)
                .orElseThrow(() -> new com.smarthas.api.web.error.ResourceNotFoundException("Alerta", alertId));

        patientService.requireAccessible(alert.getPatient().getId(), principal);
        alert.acknowledge();
        return AlertDtos.AlertResponse.from(alert);
    }

    /**
     * Gera alertas a partir de uma nova leitura.
     *
     * <p>Mesma regra do {@code AlertEngine} do app. Um alerta ja aberto para a
     * mesma metrica nao e duplicado — o paciente nao recebe a mesma notificacao
     * a cada leitura enquanto a alteracao persistir.</p>
     */
    @Transactional
    public List<HealthAlert> generateFrom(VitalReading reading) {
        Patient patient = reading.getPatient();
        List<HealthAlert> created = new java.util.ArrayList<>();

        for (VitalDtos.VitalEvaluation evaluation : scoreCalculator.evaluate(reading)) {
            HealthScoreCalculator.Status status = HealthScoreCalculator.Status.valueOf(evaluation.status());
            if (status == HealthScoreCalculator.Status.NORMAL) {
                continue;
            }
            if (alerts.existsByPatientIdAndMetricAndAcknowledgedFalse(patient.getId(), evaluation.metric())) {
                continue;
            }

            boolean critical = status == HealthScoreCalculator.Status.CRITICAL;
            String description = critical
                    ? evaluation.rationale() + " Havendo sintomas, acione o 192 (SAMU)."
                    : evaluation.rationale();

            created.add(alerts.save(new HealthAlert(
                    patient,
                    critical ? AlertType.URGENT : AlertType.WARNING,
                    "%s: %s %s".formatted(evaluation.metric(), evaluation.value(), evaluation.unit()),
                    description,
                    evaluation.metric())));
        }

        return created;
    }

    public long countOpen() {
        return alerts.countByAcknowledgedFalse();
    }

    public long countOpenUrgent() {
        return alerts.countByAcknowledgedFalseAndType(AlertType.URGENT);
    }
}
