package com.smarthas.api.web;

import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.service.PatientService;
import com.smarthas.api.service.VitalService;
import com.smarthas.api.web.dto.PatientDtos;
import com.smarthas.api.web.dto.VitalDtos;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/** Prontuarios e os sinais vitais de cada paciente. */
@RestController
@RequestMapping("/api/v1/patients")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Pacientes", description = "CRUD de prontuarios e ingestao de sinais vitais")
public class PatientController {

    private final PatientService patientService;
    private final VitalService vitalService;

    public PatientController(PatientService patientService, VitalService vitalService) {
        this.patientService = patientService;
        this.vitalService = vitalService;
    }

    @GetMapping
    @Operation(summary = "Lista prontuarios (o paciente ve apenas o proprio)")
    public List<PatientDtos.PatientResponse> list(
            @Parameter(description = "Filtro por nome") @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "20") int limit,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return patientService.list(search, limit, principal);
    }

    @GetMapping("/{id}")
    @Operation(summary = "Detalha um prontuario")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Prontuario encontrado"),
            @ApiResponse(responseCode = "403", description = "Prontuario de outro paciente"),
            @ApiResponse(responseCode = "404", description = "Paciente inexistente")
    })
    public PatientDtos.PatientResponse get(@PathVariable Long id,
                                           @AuthenticationPrincipal AppUserPrincipal principal) {
        return patientService.get(id, principal);
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('PROFESSIONAL','ADMIN')")
    @Operation(summary = "Cadastra um prontuario")
    public ResponseEntity<PatientDtos.PatientResponse> create(
            @Valid @RequestBody PatientDtos.PatientRequest request) {
        PatientDtos.PatientResponse created = patientService.create(request);
        return ResponseEntity.created(URI.create("/api/v1/patients/" + created.id())).body(created);
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('PROFESSIONAL','ADMIN')")
    @Operation(summary = "Atualiza um prontuario")
    public PatientDtos.PatientResponse update(@PathVariable Long id,
                                              @Valid @RequestBody PatientDtos.PatientRequest request) {
        return patientService.update(id, request);
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Remove um prontuario")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        patientService.delete(id);
        return ResponseEntity.noContent().build();
    }

    // ─── Sinais vitais do paciente ────────────────────────────────────────────

    @PostMapping("/{id}/vitals")
    @Operation(summary = "Registra uma leitura do wearable e gera alertas automaticos")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Leitura registrada"),
            @ApiResponse(responseCode = "400", description = "Valores fora do range fisiologico")
    })
    public ResponseEntity<VitalDtos.VitalResponse> recordVital(
            @PathVariable Long id,
            @Valid @RequestBody VitalDtos.VitalRequest request,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        VitalDtos.VitalResponse created = vitalService.record(id, request, principal);
        return ResponseEntity.created(URI.create("/api/v1/patients/" + id + "/vitals/latest")).body(created);
    }

    @GetMapping("/{id}/vitals/latest")
    @Operation(summary = "Ultima leitura registrada")
    public VitalDtos.VitalResponse latestVital(@PathVariable Long id,
                                               @AuthenticationPrincipal AppUserPrincipal principal) {
        return vitalService.latest(id, principal);
    }

    @GetMapping("/{id}/vitals")
    @Operation(summary = "Historico de leituras, mais recente primeiro")
    public List<VitalDtos.VitalResponse> vitalHistory(@PathVariable Long id,
                                                      @RequestParam(defaultValue = "50") int limit,
                                                      @AuthenticationPrincipal AppUserPrincipal principal) {
        return vitalService.history(id, limit, principal);
    }

    @GetMapping("/{id}/health-score")
    @Operation(summary = "Score de saude calculado a partir da ultima leitura")
    public VitalDtos.HealthScoreResponse healthScore(@PathVariable Long id,
                                                     @AuthenticationPrincipal AppUserPrincipal principal) {
        return vitalService.score(id, principal);
    }
}
