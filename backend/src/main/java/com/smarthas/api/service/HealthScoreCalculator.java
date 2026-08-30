package com.smarthas.api.service;

import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.web.dto.VitalDtos;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import org.springframework.stereotype.Service;

/**
 * Motor de regras que converte sinais vitais em um score de 0 a 100.
 *
 * <p>Espelha, no servidor, as mesmas faixas e pesos do
 * {@code HealthScoreEngine} implementado no app Flutter. Ter a regra tambem no
 * back-end garante que o painel administrativo, o dashboard Angular e qualquer
 * outro cliente cheguem ao mesmo numero — o app calcula localmente apenas para
 * responder de imediato quando esta offline.</p>
 */
@Service
public class HealthScoreCalculator {

    /** Faixa de referencia de um sinal vital. */
    public record VitalRange(String metric, String unit,
                             double normalMin, double normalMax,
                             double attentionMin, double attentionMax,
                             int weight) {

        public Status classify(double value) {
            if (value >= normalMin && value <= normalMax) {
                return Status.NORMAL;
            }
            if (value >= attentionMin && value <= attentionMax) {
                return Status.ATTENTION;
            }
            return Status.CRITICAL;
        }
    }

    public enum Status {
        NORMAL,
        ATTENTION,
        CRITICAL
    }

    public static final VitalRange HEART_RATE =
            new VitalRange("Freq. cardiaca", "bpm", 60, 100, 50, 110, 18);
    public static final VitalRange SPO2 =
            new VitalRange("SpO2", "%", 95, 100, 90, 100, 22);
    public static final VitalRange GLUCOSE =
            new VitalRange("Glicemia", "mg/dL", 70, 120, 60, 180, 22);
    public static final VitalRange SYSTOLIC =
            new VitalRange("Pressao sistolica", "mmHg", 90, 129, 85, 139, 18);
    public static final VitalRange DIASTOLIC =
            new VitalRange("Pressao diastolica", "mmHg", 60, 84, 55, 89, 10);
    public static final VitalRange TEMPERATURE =
            new VitalRange("Temperatura", "C", 35.5, 37.5, 35.0, 38.5, 10);

    private static final List<VitalRange> RANGES =
            List.of(HEART_RATE, SPO2, GLUCOSE, SYSTOLIC, DIASTOLIC, TEMPERATURE);

    /** Resultado consolidado do calculo. */
    public record ScoreResult(int score, String level, String label,
                              Map<String, Integer> penalties,
                              List<VitalDtos.VitalEvaluation> evaluations) {
    }

    /** Avalia cada sinal da leitura, com justificativa em texto. */
    public List<VitalDtos.VitalEvaluation> evaluate(VitalReading reading) {
        List<VitalDtos.VitalEvaluation> evaluations = new ArrayList<>(RANGES.size());
        evaluations.add(evaluateOne(HEART_RATE, reading.getHeartRate(), String.valueOf(reading.getHeartRate())));
        evaluations.add(evaluateOne(SPO2, reading.getSpO2(), String.format(Locale.ROOT, "%.1f", reading.getSpO2())));
        evaluations.add(evaluateOne(GLUCOSE, reading.getGlucoseLevel(), String.valueOf(reading.getGlucoseLevel())));
        evaluations.add(evaluateOne(SYSTOLIC, reading.getBpSystolic(), String.valueOf(reading.getBpSystolic())));
        evaluations.add(evaluateOne(DIASTOLIC, reading.getBpDiastolic(), String.valueOf(reading.getBpDiastolic())));
        evaluations.add(evaluateOne(TEMPERATURE, reading.getTemperature(),
                String.format(Locale.ROOT, "%.1f", reading.getTemperature())));
        return evaluations;
    }

    /** Calcula o score aplicando as penalidades de cada metrica fora da faixa. */
    public ScoreResult calculate(VitalReading reading) {
        List<VitalDtos.VitalEvaluation> evaluations = evaluate(reading);
        Map<String, Integer> penalties = new LinkedHashMap<>();

        int total = 100;
        for (VitalDtos.VitalEvaluation evaluation : evaluations) {
            VitalRange range = rangeFor(evaluation.metric());
            int penalty = switch (Status.valueOf(evaluation.status())) {
                case NORMAL -> 0;
                case ATTENTION -> (int) Math.round(range.weight() * 0.4);
                case CRITICAL -> range.weight();
            };
            if (penalty > 0) {
                penalties.put(evaluation.metric(), penalty);
            }
            total -= penalty;
        }

        int score = Math.max(0, Math.min(100, total));
        String level = levelFor(score);
        return new ScoreResult(score, level, labelFor(level), penalties, evaluations);
    }

    public static String levelFor(int score) {
        if (score >= 90) {
            return "EXCELLENT";
        }
        if (score >= 75) {
            return "GOOD";
        }
        if (score >= 60) {
            return "MEDIUM";
        }
        if (score >= 40) {
            return "LOW";
        }
        return "CRITICAL";
    }

    public static String labelFor(String level) {
        return switch (level) {
            case "EXCELLENT" -> "EXCELENTE";
            case "GOOD" -> "BOM";
            case "MEDIUM" -> "MODERADO";
            case "LOW" -> "ATENCAO";
            default -> "CRITICO";
        };
    }

    /** Tendencia em relacao ao score anterior (estavel dentro de 2 pontos). */
    public static String trend(int score, Integer previousScore) {
        if (previousScore == null || Math.abs(score - previousScore) <= 2) {
            return "STABLE";
        }
        return score > previousScore ? "UP" : "DOWN";
    }

    private VitalDtos.VitalEvaluation evaluateOne(VitalRange range, double value, String display) {
        Status status = range.classify(value);
        String reference = "%s-%s %s".formatted(
                trim(range.normalMin()), trim(range.normalMax()), range.unit());
        String rationale = switch (status) {
            case NORMAL -> "Dentro da faixa de referencia (" + reference + ").";
            case ATTENTION -> "Fora da faixa ideal (" + reference + "). Monitorar.";
            case CRITICAL -> "Valor critico para a faixa de referencia (" + reference + ").";
        };
        return new VitalDtos.VitalEvaluation(range.metric(), display, range.unit(), status.name(), rationale);
    }

    private VitalRange rangeFor(String metric) {
        return RANGES.stream()
                .filter(range -> range.metric().equals(metric))
                .findFirst()
                .orElse(TEMPERATURE);
    }

    /**
     * Formatacao independente de locale: o JSON precisa usar ponto decimal
     * mesmo quando o servidor roda com locale pt-BR.
     */
    private static String trim(double value) {
        return value == Math.rint(value) ? String.valueOf((long) value) : String.valueOf(value);
    }
}
