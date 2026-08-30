package com.smarthas.api.service;

import com.smarthas.api.domain.DeliveryStatus;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.repository.VitalReadingRepository;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.web.dto.AnalyticsDtos;
import com.smarthas.api.web.dto.VitalDtos;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Series historicas do paciente e indicadores operacionais consolidados. */
@Service
public class AnalyticsService {

    private final VitalReadingRepository readings;
    private final PatientService patientService;
    private final VitalService vitalService;
    private final AlertService alertService;
    private final DeliveryService deliveryService;
    private final ScheduleService scheduleService;

    public AnalyticsService(VitalReadingRepository readings, PatientService patientService,
                            VitalService vitalService, AlertService alertService,
                            DeliveryService deliveryService, ScheduleService scheduleService) {
        this.readings = readings;
        this.patientService = patientService;
        this.vitalService = vitalService;
        this.alertService = alertService;
        this.deliveryService = deliveryService;
        this.scheduleService = scheduleService;
    }

    /** Metricas e insights do periodo solicitado (7, 14 ou 30 dias). */
    @Transactional(readOnly = true)
    public AnalyticsDtos.PatientAnalyticsResponse patientAnalytics(Long patientId, int periodDays,
                                                                   AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);

        int days = Math.min(Math.max(periodDays, 1), 90);
        Instant since = Instant.now().minus(days, ChronoUnit.DAYS);
        List<VitalReading> period = readings.findByPatientIdAndMeasuredAtAfterOrderByMeasuredAtAsc(patientId, since);

        List<AnalyticsDtos.MetricSeries> metrics = List.of(
                series("Freq. Cardiaca", "bpm", period, r -> r.getHeartRate().doubleValue(), 0, false),
                series("SpO2", "%", period, VitalReading::getSpO2, 1, true),
                series("Glicemia", "mg/dL", period, r -> r.getGlucoseLevel().doubleValue(), 0, false),
                series("Pressao Sistolica", "mmHg", period, r -> r.getBpSystolic().doubleValue(), 0, false));

        List<AnalyticsDtos.Insight> insights = new ArrayList<>();
        VitalDtos.HealthScoreResponse score = null;

        if (!period.isEmpty()) {
            score = vitalService.score(patientId, principal);
            insights.add(scoreInsight(score, days));
        } else {
            insights.add(new AnalyticsDtos.Insight(
                    "Sem leituras no periodo",
                    "Nenhuma medicao foi recebida nos ultimos " + days + " dias. "
                            + "Verifique a conexao do wearable.",
                    "WARNING"));
        }

        return new AnalyticsDtos.PatientAnalyticsResponse(
                patientId, days, period.size(), metrics, insights, score);
    }

    /** Indicadores da operacao usados pelo painel Thymeleaf e pelo dashboard. */
    @Transactional(readOnly = true)
    public AnalyticsDtos.OverviewResponse overview() {
        Map<String, Long> byStatus = deliveryService.countByStatus();

        return new AnalyticsDtos.OverviewResponse(
                patientService.count(),
                alertService.countOpen(),
                alertService.countOpenUrgent(),
                deliveryService.countByStatus(DeliveryStatus.IN_TRANSIT),
                deliveryService.countByStatus(DeliveryStatus.DELIVERED),
                scheduleService.countUpcoming(),
                byStatus);
    }

    private AnalyticsDtos.Insight scoreInsight(VitalDtos.HealthScoreResponse score, int days) {
        String worst = score.penalties().entrySet().stream()
                .max(Comparator.comparingInt(Map.Entry::getValue))
                .map(Map.Entry::getKey)
                .orElse(null);

        String description = worst == null
                ? "Nenhuma metrica saiu da faixa de referencia nos ultimos " + days + " dias."
                : "A metrica que mais reduz o score e " + worst + ". Priorize esse ponto na semana.";

        String severity = switch (score.level()) {
            case "CRITICAL", "LOW" -> "CRITICAL";
            case "MEDIUM" -> "WARNING";
            default -> "INFO";
        };

        return new AnalyticsDtos.Insight(
                "Score de saude: %d/100 (%s)".formatted(score.score(), score.label()),
                description,
                severity);
    }

    /**
     * Monta a serie de uma metrica.
     *
     * <p>{@code higherIsBetter} define o significado da seta de tendencia: para
     * SpO2 subir e bom; para glicemia e pressao, nao.</p>
     */
    private AnalyticsDtos.MetricSeries series(String label, String unit, List<VitalReading> period,
                                              Function<VitalReading, Double> extractor,
                                              int decimals, boolean higherIsBetter) {
        List<Double> values = period.stream()
                .map(extractor)
                .map(value -> round(value, decimals))
                .toList();

        if (values.isEmpty()) {
            return new AnalyticsDtos.MetricSeries(label, unit, "--", "Sem dados no periodo", true, List.of());
        }

        double first = values.get(0);
        double current = values.get(values.size() - 1);
        double delta = round(current - first, decimals);

        String trend = Math.abs(delta) < 0.05
                ? "Estavel no periodo"
                : "%s%s %s vs. inicio do periodo".formatted(delta > 0 ? "+" : "", format(delta, decimals), unit);

        boolean improving = Math.abs(delta) < 0.05 || (higherIsBetter == (delta > 0));

        return new AnalyticsDtos.MetricSeries(label, unit, format(current, decimals), trend, improving, values);
    }

    private static double round(double value, int decimals) {
        double factor = Math.pow(10, decimals);
        return Math.round(value * factor) / factor;
    }

    /** Ponto decimal fixo: o cliente Dart faz double.parse do valor recebido. */
    private static String format(double value, int decimals) {
        return decimals == 0 ? String.valueOf((long) value) : String.format(Locale.ROOT, "%." + decimals + "f", value);
    }
}
