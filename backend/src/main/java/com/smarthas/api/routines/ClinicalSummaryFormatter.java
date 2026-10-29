package com.smarthas.api.routines;

import com.smarthas.api.domain.Patient;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.service.HealthScoreCalculator;
import java.math.RoundingMode;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.stream.Collectors;

/**
 * Textos do relatorio no motor Java, identicos aos das functions
 * {@code FN_ROTULO_NIVEL}, {@code FN_FORMATAR_LEITURA} e
 * {@code FN_FORMATAR_RESUMO_PACIENTE}.
 *
 * <p>O padrao e brasileiro (virgula decimal, horario de Brasilia) porque o
 * texto e lido por pessoas; os campos numericos do JSON continuam com ponto.</p>
 */
final class ClinicalSummaryFormatter {

    private static final ZoneId BRASILIA = ZoneId.of("America/Sao_Paulo");
    private static final DateTimeFormatter DATE_TIME = DateTimeFormatter.ofPattern("dd/MM/yyyy HH:mm");

    private ClinicalSummaryFormatter() {
    }

    /** {@code FN_ROTULO_NIVEL}. */
    static String riskLabel(Integer score) {
        return score == null
                ? "SEM DADOS"
                : HealthScoreCalculator.labelFor(HealthScoreCalculator.levelFor(score));
    }

    /** {@code FN_FORMATAR_LEITURA}. */
    static String reading(VitalReading r) {
        return DATE_TIME.format(r.getMeasuredAt().atZone(BRASILIA))
                + " - FC " + r.getHeartRate() + " bpm"
                + "; SpO2 " + oneDecimal(r.getSpO2()) + "%"
                + "; Glicemia " + r.getGlucoseLevel() + " mg/dL"
                + "; PA " + r.getBpSystolic() + "/" + r.getBpDiastolic() + " mmHg"
                + "; Temp. " + oneDecimal(r.getTemperature()) + " C";
    }

    /** {@code FN_FORMATAR_RESUMO_PACIENTE}. */
    static String summary(Patient patient, Integer score, Double glucoseInRange, int periodDays,
                          int openAlerts, int urgentAlerts, VitalReading latest) {
        StringBuilder text = new StringBuilder()
                .append(patient.getName()).append(", ").append(patient.getAge()).append(" anos");

        if (!patient.getConditions().isEmpty()) {
            text.append(" (")
                    .append(patient.getConditions().stream().sorted().collect(Collectors.joining(", ")))
                    .append(")");
        }

        text.append(" | Score atual: ")
                .append(score == null ? "sem leituras" : score + "/100 - " + riskLabel(score));

        text.append(" | Glicemia na faixa: ")
                .append(glucoseInRange == null
                        ? "sem dados"
                        : oneDecimal(glucoseInRange) + "% das leituras em " + periodDays + " dias");

        text.append(" | Alertas abertos: ").append(openAlerts);
        if (urgentAlerts > 0) {
            text.append(" (").append(urgentAlerts).append(urgentAlerts > 1 ? " urgentes)" : " urgente)");
        }

        if (latest != null) {
            text.append(" | Ultima leitura: ").append(reading(latest));
        }

        return text.length() > 1000 ? text.substring(0, 1000) : text.toString();
    }

    /** Mascara {@code FM990D0} com virgula decimal. */
    private static String oneDecimal(double value) {
        DecimalFormat format = new DecimalFormat("0.0", DecimalFormatSymbols.getInstance(Locale.forLanguageTag("pt-BR")));
        format.setRoundingMode(RoundingMode.HALF_UP);
        return format.format(value);
    }
}
