package com.smarthas.api.web.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import java.time.Instant;
import java.util.List;

/** Contratos do relatorio clinico consolidado (Fase 6 - Oracle PL/SQL). */
public final class ReportDtos {

    private ReportDtos() {
    }

    @Schema(description = "Media de cada sinal vital no periodo")
    public record VitalAverages(
            Double heartRate,
            Double spO2,
            Double glucose,
            Double systolic,
            Double diastolic,
            Double temperature) {
    }

    @Schema(description = "Relatorio clinico e de consumo de medicamentos de um paciente")
    public record PatientReportResponse(
            Long patientId,
            String patientName,
            int periodDays,
            Instant generatedAt,
            int readings,
            VitalAverages averages,
            @Schema(description = "Score 0-100 da leitura mais recente", nullable = true)
            Integer latestScore,
            @Schema(description = "Score medio das leituras do periodo", nullable = true)
            Double averageScore,
            @Schema(example = "BOM")
            String riskLevel,
            @Schema(description = "% das leituras de glicemia dentro da faixa normal", nullable = true)
            Double glucoseTimeInRange,
            int openAlerts,
            int urgentAlerts,
            int alertsInPeriod,
            int deliveriesTotal,
            int deliveriesDelivered,
            @Schema(description = "Resumo textual formatado pela rotina do banco")
            String summary,
            @Schema(description = "Quem calculou o relatorio", allowableValues = {"ORACLE_PLSQL", "JAVA"})
            String engine) {
    }

    @Schema(description = "Resultado da consolidacao em lote")
    public record ConsolidationResponse(
            String engine,
            int periodDays,
            int processed,
            List<PatientReportResponse> reports) {
    }
}
