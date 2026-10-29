package com.smarthas.api.web;

import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.service.ReportService;
import com.smarthas.api.web.dto.ReportDtos;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Relatorios clinicos consolidados pelas rotinas do banco de dados. */
@RestController
@RequestMapping("/api/v1")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Relatorios", description = "Relatorio clinico e de consumo gerado por PL/SQL no Oracle")
public class ReportController {

    private final ReportService reportService;

    public ReportController(ReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("/patients/{patientId}/report")
    @Operation(summary = "Relatorio consolidado do paciente (PRC_CONSOLIDAR_RELATORIO)")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Relatorio consolidado"),
            @ApiResponse(responseCode = "403", description = "Prontuario de outro paciente"),
            @ApiResponse(responseCode = "422", description = "Periodo fora de 1 a 365 dias")
    })
    public ReportDtos.PatientReportResponse patientReport(
            @PathVariable Long patientId,
            @RequestParam(defaultValue = "30") int periodDays,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return reportService.patientReport(patientId, periodDays, principal);
    }

    @PostMapping("/reports/consolidation")
    @PreAuthorize("hasAnyRole('PROFESSIONAL','ADMIN')")
    @Operation(summary = "Consolida o relatorio de todos os pacientes (rotina em lote no banco)")
    public ReportDtos.ConsolidationResponse consolidateAll(@RequestParam(defaultValue = "30") int periodDays) {
        return reportService.consolidateAll(periodDays);
    }
}
