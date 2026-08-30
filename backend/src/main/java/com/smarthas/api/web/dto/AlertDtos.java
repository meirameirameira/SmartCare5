package com.smarthas.api.web.dto;

import com.smarthas.api.domain.AlertType;
import com.smarthas.api.domain.HealthAlert;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;

/** Contratos dos alertas clinicos. */
public final class AlertDtos {

    private AlertDtos() {
    }

    @Schema(description = "Alerta registrado manualmente por um profissional")
    public record AlertRequest(
            @NotNull(message = "Informe a severidade")
            AlertType type,

            @NotBlank(message = "Informe o titulo")
            @Size(max = 160, message = "Titulo muito longo")
            String title,

            @NotBlank(message = "Informe a descricao")
            @Size(max = 500, message = "Descricao muito longa")
            String description,

            @Schema(description = "Metrica de origem, quando aplicavel", nullable = true)
            String metric) {
    }

    @Schema(description = "Alerta retornado pela API")
    public record AlertResponse(
            Long id,
            Long patientId,
            AlertType type,
            String title,
            String description,
            String metric,
            boolean acknowledged,
            Instant createdAt,
            Instant acknowledgedAt) {

        public static AlertResponse from(HealthAlert alert) {
            return new AlertResponse(
                    alert.getId(),
                    alert.getPatient().getId(),
                    alert.getType(),
                    alert.getTitle(),
                    alert.getDescription(),
                    alert.getMetric(),
                    alert.isAcknowledged(),
                    alert.getCreatedAt(),
                    alert.getAcknowledgedAt());
        }
    }
}
