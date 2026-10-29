package com.smarthas.api.routines;

import com.smarthas.api.domain.AlertType;
import com.smarthas.api.domain.DeliveryStatus;
import com.smarthas.api.domain.Patient;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.repository.DeliveryOrderRepository;
import com.smarthas.api.repository.HealthAlertRepository;
import com.smarthas.api.repository.PatientRepository;
import com.smarthas.api.repository.VitalReadingRepository;
import com.smarthas.api.service.AlertService;
import com.smarthas.api.service.HealthScoreCalculator;
import com.smarthas.api.web.dto.ReportDtos;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Comparator;
import java.util.List;
import java.util.OptionalDouble;
import java.util.function.ToDoubleFunction;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Component;

/**
 * Motor clinico em Java, ativo fora do perfil {@code oracle}.
 *
 * <p>Reproduz as rotinas PL/SQL ({@code PRC_REGISTRAR_ALERTAS_LEITURA},
 * {@code PRC_CONSOLIDAR_RELATORIO} e as functions de score, tempo na faixa e
 * resumo) para que o ambiente H2 de desenvolvimento e os testes automatizados
 * exponham exatamente o mesmo contrato da API. O relatorio e calculado sob
 * demanda e nao e persistido.</p>
 */
@Component
@Profile("!oracle")
public class JavaClinicalRoutines implements ClinicalRoutines {

    public static final String ENGINE = "JAVA";

    private static final Logger log = LoggerFactory.getLogger(JavaClinicalRoutines.class);

    private final AlertService alertService;
    private final PatientRepository patients;
    private final VitalReadingRepository readings;
    private final HealthAlertRepository alerts;
    private final DeliveryOrderRepository deliveries;
    private final HealthScoreCalculator scoreCalculator;

    public JavaClinicalRoutines(AlertService alertService, PatientRepository patients,
                                VitalReadingRepository readings, HealthAlertRepository alerts,
                                DeliveryOrderRepository deliveries, HealthScoreCalculator scoreCalculator) {
        this.alertService = alertService;
        this.patients = patients;
        this.readings = readings;
        this.alerts = alerts;
        this.deliveries = deliveries;
        this.scoreCalculator = scoreCalculator;
        log.info("Motor clinico: Java (perfil sem Oracle).");
    }

    @Override
    public String engine() {
        return ENGINE;
    }

    @Override
    public int generateAlerts(VitalReading reading) {
        return alertService.generateFrom(reading).size();
    }

    @Override
    public ReportDtos.PatientReportResponse consolidate(Patient patient, int periodDays) {
        Instant now = Instant.now();
        Instant since = now.minus(periodDays, ChronoUnit.DAYS);
        Long id = patient.getId();

        List<VitalReading> period = readings.findByPatientIdAndMeasuredAtAfterOrderByMeasuredAtAsc(id, since);
        VitalReading latest = readings.findFirstByPatientIdOrderByMeasuredAtDesc(id).orElse(null);

        Integer latestScore = latest == null ? null : scoreCalculator.calculate(latest).score();
        Double averageScore = average(period, r -> scoreCalculator.calculate(r).score());
        Double glucoseInRange = glucoseTimeInRange(period);

        int openAlerts = (int) alerts.countByPatientIdAndAcknowledgedFalse(id);
        int urgentAlerts = (int) alerts.countByPatientIdAndAcknowledgedFalseAndType(id, AlertType.URGENT);

        return new ReportDtos.PatientReportResponse(
                id,
                patient.getName(),
                periodDays,
                now,
                period.size(),
                new ReportDtos.VitalAverages(
                        average(period, VitalReading::getHeartRate),
                        average(period, VitalReading::getSpO2),
                        average(period, VitalReading::getGlucoseLevel),
                        average(period, VitalReading::getBpSystolic),
                        average(period, VitalReading::getBpDiastolic),
                        average(period, VitalReading::getTemperature)),
                latestScore,
                averageScore,
                ClinicalSummaryFormatter.riskLabel(latestScore),
                glucoseInRange,
                openAlerts,
                urgentAlerts,
                (int) alerts.countByPatientIdAndCreatedAtAfter(id, since),
                (int) deliveries.countByPatientIdAndCreatedAtAfterAndStatusNot(id, since, DeliveryStatus.CANCELLED),
                (int) deliveries.countByPatientIdAndCreatedAtAfterAndStatus(id, since, DeliveryStatus.DELIVERED),
                ClinicalSummaryFormatter.summary(patient, latestScore, glucoseInRange, periodDays,
                        openAlerts, urgentAlerts, latest),
                ENGINE);
    }

    @Override
    public List<ReportDtos.PatientReportResponse> consolidateAll(int periodDays) {
        return patients.findAll(Sort.by("id")).stream()
                .map(patient -> consolidate(patient, periodDays))
                .sorted(Comparator.comparing(ReportDtos.PatientReportResponse::latestScore,
                                Comparator.nullsLast(Comparator.naturalOrder()))
                        .thenComparing(ReportDtos.PatientReportResponse::patientName))
                .toList();
    }

    /** Equivalente a {@code FN_TEMPO_NA_FAIXA(paciente, 'GLUCOSE', dias)}. */
    private static Double glucoseTimeInRange(List<VitalReading> period) {
        if (period.isEmpty()) {
            return null;
        }
        HealthScoreCalculator.VitalRange range = HealthScoreCalculator.GLUCOSE;
        long inRange = period.stream()
                .filter(r -> r.getGlucoseLevel() >= range.normalMin() && r.getGlucoseLevel() <= range.normalMax())
                .count();
        return round(inRange * 100.0 / period.size());
    }

    /** Equivalente a {@code ROUND(AVG(coluna), 1)}: nulo quando nao ha leituras. */
    private static <T> Double average(List<T> values, ToDoubleFunction<T> extractor) {
        OptionalDouble mean = values.stream().mapToDouble(extractor).average();
        return mean.isPresent() ? round(mean.getAsDouble()) : null;
    }

    private static double round(double value) {
        return BigDecimal.valueOf(value).setScale(1, RoundingMode.HALF_UP).doubleValue();
    }
}
