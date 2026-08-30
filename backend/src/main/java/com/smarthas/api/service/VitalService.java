package com.smarthas.api.service;

import com.smarthas.api.domain.Patient;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.repository.VitalReadingRepository;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.web.dto.VitalDtos;
import com.smarthas.api.web.error.BusinessRuleException;
import com.smarthas.api.web.error.ResourceNotFoundException;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Ingestao e consulta de sinais vitais, com calculo do score de saude. */
@Service
public class VitalService {

    private final VitalReadingRepository readings;
    private final PatientService patientService;
    private final AlertService alertService;
    private final HealthScoreCalculator scoreCalculator;

    public VitalService(VitalReadingRepository readings, PatientService patientService,
                        AlertService alertService, HealthScoreCalculator scoreCalculator) {
        this.readings = readings;
        this.patientService = patientService;
        this.alertService = alertService;
        this.scoreCalculator = scoreCalculator;
    }

    /**
     * Registra uma leitura do wearable e dispara a geracao de alertas.
     *
     * <p>Tudo em uma unica transacao: ou a leitura e os alertas derivados sao
     * gravados juntos, ou nada e gravado.</p>
     */
    @Transactional
    public VitalDtos.VitalResponse record(Long patientId, VitalDtos.VitalRequest request,
                                          AppUserPrincipal principal) {
        Patient patient = patientService.requireAccessible(patientId, principal);

        Instant measuredAt = request.measuredAt() == null ? Instant.now() : request.measuredAt();
        if (measuredAt.isAfter(Instant.now().plus(5, ChronoUnit.MINUTES))) {
            throw new BusinessRuleException("A data da medicao nao pode estar no futuro.");
        }

        VitalReading reading = readings.save(new VitalReading(
                patient,
                request.heartRate(),
                request.spO2(),
                request.glucoseLevel(),
                request.bpSystolic(),
                request.bpDiastolic(),
                request.temperature(),
                measuredAt));

        alertService.generateFrom(reading);

        return VitalDtos.VitalResponse.from(reading);
    }

    @Transactional(readOnly = true)
    public VitalDtos.VitalResponse latest(Long patientId, AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);
        return readings.findFirstByPatientIdOrderByMeasuredAtDesc(patientId)
                .map(VitalDtos.VitalResponse::from)
                .orElseThrow(() -> new ResourceNotFoundException(
                        "Nenhuma leitura registrada para o paciente " + patientId + "."));
    }

    @Transactional(readOnly = true)
    public List<VitalDtos.VitalResponse> history(Long patientId, int limit, AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);
        return readings
                .findByPatientIdOrderByMeasuredAtDesc(patientId,
                        PageRequest.of(0, Math.min(Math.max(limit, 1), 500)))
                .stream()
                .map(VitalDtos.VitalResponse::from)
                .toList();
    }

    /** Score da ultima leitura, com a tendencia calculada sobre a penultima. */
    @Transactional(readOnly = true)
    public VitalDtos.HealthScoreResponse score(Long patientId, AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);

        List<VitalReading> lastTwo = readings.findByPatientIdOrderByMeasuredAtDesc(patientId, PageRequest.of(0, 2));
        if (lastTwo.isEmpty()) {
            throw new ResourceNotFoundException(
                    "Nenhuma leitura registrada para o paciente " + patientId + ".");
        }

        VitalReading current = lastTwo.get(0);
        Integer previousScore = lastTwo.size() > 1
                ? scoreCalculator.calculate(lastTwo.get(1)).score()
                : null;

        HealthScoreCalculator.ScoreResult result = scoreCalculator.calculate(current);

        return new VitalDtos.HealthScoreResponse(
                result.score(),
                result.level(),
                result.label(),
                HealthScoreCalculator.trend(result.score(), previousScore),
                result.penalties(),
                result.evaluations(),
                VitalDtos.VitalResponse.from(current));
    }

    @Transactional(readOnly = true)
    public Optional<VitalReading> latestEntity(Long patientId) {
        return readings.findFirstByPatientIdOrderByMeasuredAtDesc(patientId);
    }
}
