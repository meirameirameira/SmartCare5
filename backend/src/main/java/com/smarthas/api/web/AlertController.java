package com.smarthas.api.web;

import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.service.AlertService;
import com.smarthas.api.web.dto.AlertDtos;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Alertas clinicos do paciente. */
@RestController
@RequestMapping("/api/v1")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Alertas", description = "Alertas gerados pelo motor de regras ou registrados pela equipe")
public class AlertController {

    private final AlertService alertService;

    public AlertController(AlertService alertService) {
        this.alertService = alertService;
    }

    @GetMapping("/patients/{patientId}/alerts")
    @Operation(summary = "Lista os alertas do paciente")
    public List<AlertDtos.AlertResponse> list(
            @PathVariable Long patientId,
            @RequestParam(defaultValue = "false") boolean onlyOpen,
            @RequestParam(defaultValue = "20") int limit,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return alertService.listByPatient(patientId, onlyOpen, limit, principal);
    }

    @PostMapping("/patients/{patientId}/alerts")
    @PreAuthorize("hasAnyRole('PROFESSIONAL','ADMIN')")
    @Operation(summary = "Registra um alerta manualmente (equipe assistencial)")
    public ResponseEntity<AlertDtos.AlertResponse> create(
            @PathVariable Long patientId,
            @Valid @RequestBody AlertDtos.AlertRequest request,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(alertService.create(patientId, request, principal));
    }

    @PatchMapping("/alerts/{alertId}/acknowledge")
    @Operation(summary = "Marca o alerta como tratado (operacao idempotente)")
    public AlertDtos.AlertResponse acknowledge(@PathVariable Long alertId,
                                               @AuthenticationPrincipal AppUserPrincipal principal) {
        return alertService.acknowledge(alertId, principal);
    }
}
