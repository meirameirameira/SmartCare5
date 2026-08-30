package com.smarthas.api.web.dto;

import com.smarthas.api.domain.VitalReading;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.Map;

/** Contratos de sinais vitais e do score de saude. */
public final class VitalDtos {

    private VitalDtos() {
    }

    @Schema(description = "Leitura enviada pelo wearable")
    public record VitalRequest(
            @NotNull(message = "Informe a frequencia cardiaca")
            @Min(value = 20, message = "Frequencia cardiaca fora do range fisiologico")
            @Max(value = 250, message = "Frequencia cardiaca fora do range fisiologico")
            @Schema(example = "72")
            Integer heartRate,

            @NotNull(message = "Informe a SpO2")
            @DecimalMin(value = "50.0", message = "SpO2 fora do range fisiologico")
            @DecimalMax(value = "100.0", message = "SpO2 fora do range fisiologico")
            @Schema(example = "98.5")
            Double spO2,

            @NotNull(message = "Informe a glicemia")
            @Min(value = 20, message = "Glicemia fora do range fisiologico")
            @Max(value = 600, message = "Glicemia fora do range fisiologico")
            @Schema(example = "104")
            Integer glucoseLevel,

            @NotNull(message = "Informe a pressao sistolica")
            @Min(value = 50, message = "Pressao sistolica fora do range fisiologico")
            @Max(value = 260, message = "Pressao sistolica fora do range fisiologico")
            @Schema(example = "118")
            Integer bpSystolic,

            @NotNull(message = "Informe a pressao diastolica")
            @Min(value = 30, message = "Pressao diastolica fora do range fisiologico")
            @Max(value = 160, message = "Pressao diastolica fora do range fisiologico")
            @Schema(example = "78")
            Integer bpDiastolic,

            @NotNull(message = "Informe a temperatura")
            @DecimalMin(value = "30.0", message = "Temperatura fora do range fisiologico")
            @DecimalMax(value = "45.0", message = "Temperatura fora do range fisiologico")
            @Schema(example = "36.6")
            Double temperature,

            @Schema(description = "Momento da medicao; assume agora quando omitido", nullable = true)
            Instant measuredAt) {
    }

    @Schema(description = "Leitura persistida")
    public record VitalResponse(
            Long id,
            Long patientId,
            Integer heartRate,
            Double spO2,
            Integer glucoseLevel,
            Integer bpSystolic,
            Integer bpDiastolic,
            Double temperature,
            Instant measuredAt) {

        public static VitalResponse from(VitalReading reading) {
            return new VitalResponse(
                    reading.getId(),
                    reading.getPatient().getId(),
                    reading.getHeartRate(),
                    reading.getSpO2(),
                    reading.getGlucoseLevel(),
                    reading.getBpSystolic(),
                    reading.getBpDiastolic(),
                    reading.getTemperature(),
                    reading.getMeasuredAt());
        }
    }

    @Schema(description = "Classificacao de um sinal vital isolado")
    public record VitalEvaluation(
            String metric,
            String value,
            String unit,
            String status,
            String rationale) {
    }

    @Schema(description = "Score de saude calculado no servidor")
    public record HealthScoreResponse(
            int score,
            String level,
            String label,
            String trend,
            @Schema(description = "Pontos descontados por metrica")
            Map<String, Integer> penalties,
            List<VitalEvaluation> evaluations,
            VitalResponse latestReading) {
    }
}
