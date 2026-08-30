package com.smarthas.api.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.List;
import java.util.Map;

/** Contratos de analytics: series do paciente e visao geral da operacao. */
public final class AnalyticsDtos {

    private AnalyticsDtos() {
    }

    @Schema(description = "Serie temporal de uma metrica")
    public record MetricSeries(
            String label,
            String unit,
            String currentValue,
            String trend,
            boolean trendUp,
            List<Double> values) {
    }

    @Schema(description = "Insight gerado a partir dos dados do periodo")
    public record Insight(String title, String description, String severity) {
    }

    @Schema(description = "Analytics de um paciente")
    public record PatientAnalyticsResponse(
            Long patientId,
            int periodDays,
            int readings,
            List<MetricSeries> metrics,
            List<Insight> insights,
            VitalDtos.HealthScoreResponse score) {
    }

    @Schema(description = "Visao geral da operacao, usada pelo painel administrativo")
    public record OverviewResponse(
            long totalPatients,
            long openAlerts,
            long urgentAlerts,
            long deliveriesInTransit,
            long deliveriesDelivered,
            long upcomingAppointments,
            Map<String, Long> deliveriesByStatus) {
    }
}
