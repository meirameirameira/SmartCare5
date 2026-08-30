package com.smarthas.api.web;

import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.service.AnalyticsService;
import com.smarthas.api.web.dto.AnalyticsDtos;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Analytics do paciente e indicadores da operacao. */
@RestController
@RequestMapping("/api/v1/analytics")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Analytics", description = "Series historicas, insights e visao geral da operacao")
public class AnalyticsController {

    private final AnalyticsService analyticsService;

    public AnalyticsController(AnalyticsService analyticsService) {
        this.analyticsService = analyticsService;
    }

    @GetMapping("/patients/{patientId}")
    @Operation(summary = "Series e insights do paciente no periodo")
    public AnalyticsDtos.PatientAnalyticsResponse patient(
            @PathVariable Long patientId,
            @RequestParam(defaultValue = "7") int periodDays,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return analyticsService.patientAnalytics(patientId, periodDays, principal);
    }

    @GetMapping("/overview")
    @PreAuthorize("hasAnyRole('PROFESSIONAL','ADMIN')")
    @Operation(summary = "Indicadores consolidados da operacao")
    public AnalyticsDtos.OverviewResponse overview() {
        return analyticsService.overview();
    }
}
