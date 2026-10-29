package com.smarthas.api.routines;

import static org.assertj.core.api.Assertions.assertThat;

import com.smarthas.api.service.HealthScoreCalculator;
import com.smarthas.api.service.HealthScoreCalculator.VitalRange;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Garante que as faixas clinicas carregadas no Oracle sao as mesmas do motor
 * Java. Sem este teste, ajustar um limite em um lado e esquecer o outro faria
 * o app mostrar um score diferente conforme o perfil em que a API sobe.
 */
@DisplayName("Paridade das faixas de referencia Oracle x Java")
class ReferenceRangeParityTest {

    private static final Path SEED = Path.of("..", "database", "oracle", "04_carga_dados.sql");

    private static final Pattern RANGE_INSERT = Pattern.compile(
            "INSERT INTO vital_reference_range VALUES \\('(\\w+)',\\s*'([^']+)',\\s*'([^']+)',"
                    + "\\s*([\\d.]+),\\s*([\\d.]+),\\s*([\\d.]+),\\s*([\\d.]+),\\s*(\\d+),\\s*\\d+\\);");

    private record SqlRange(String metricName, String unit, double normalMin, double normalMax,
                            double attentionMin, double attentionMax, int weight) {
    }

    private static Map<String, SqlRange> rangesFromSeed() throws IOException {
        String sql = Files.readString(SEED, StandardCharsets.UTF_8);
        Matcher matcher = RANGE_INSERT.matcher(sql);
        Map<String, SqlRange> ranges = new HashMap<>();
        while (matcher.find()) {
            ranges.put(matcher.group(2), new SqlRange(
                    matcher.group(2), matcher.group(3),
                    Double.parseDouble(matcher.group(4)), Double.parseDouble(matcher.group(5)),
                    Double.parseDouble(matcher.group(6)), Double.parseDouble(matcher.group(7)),
                    Integer.parseInt(matcher.group(8))));
        }
        return ranges;
    }

    @Test
    @DisplayName("cada faixa do HealthScoreCalculator existe no seed Oracle com os mesmos valores")
    void sqlSeedMatchesJavaCalculator() throws IOException {
        Map<String, SqlRange> sql = rangesFromSeed();
        List<VitalRange> java = List.of(HealthScoreCalculator.HEART_RATE, HealthScoreCalculator.SPO2,
                HealthScoreCalculator.GLUCOSE, HealthScoreCalculator.SYSTOLIC,
                HealthScoreCalculator.DIASTOLIC, HealthScoreCalculator.TEMPERATURE);

        assertThat(sql).hasSize(java.size());
        for (VitalRange range : java) {
            // metric_name e o texto gravado em health_alert.metric: precisa ser
            // identico para a deduplicacao funcionar entre os dois motores.
            assertThat(sql).containsKey(range.metric());
            assertThat(sql.get(range.metric())).isEqualTo(new SqlRange(
                    range.metric(), range.unit(), range.normalMin(), range.normalMax(),
                    range.attentionMin(), range.attentionMax(), range.weight()));
        }
    }
}
