package com.smarthas.api.web;

import com.smarthas.api.domain.AppointmentStatus;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.service.ScheduleService;
import com.smarthas.api.web.dto.ScheduleDtos;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import java.net.URI;
import java.util.List;
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

/** Teleconsulta: profissionais e agendamentos. */
@RestController
@RequestMapping("/api/v1")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Teleconsulta", description = "Profissionais disponiveis e agenda de consultas")
public class ScheduleController {

    private final ScheduleService scheduleService;

    public ScheduleController(ScheduleService scheduleService) {
        this.scheduleService = scheduleService;
    }

    @GetMapping("/doctors")
    @Operation(summary = "Lista profissionais")
    public List<ScheduleDtos.DoctorResponse> listDoctors(
            @RequestParam(required = false) String specialty,
            @RequestParam(defaultValue = "false") boolean onlyAvailable) {
        return scheduleService.listDoctors(specialty, onlyAvailable);
    }

    @PostMapping("/doctors")
    @PreAuthorize("hasAnyRole('PROFESSIONAL','ADMIN')")
    @Operation(summary = "Cadastra um profissional")
    public ResponseEntity<ScheduleDtos.DoctorResponse> createDoctor(
            @Valid @RequestBody ScheduleDtos.DoctorRequest request) {
        ScheduleDtos.DoctorResponse created = scheduleService.createDoctor(request);
        return ResponseEntity.created(URI.create("/api/v1/doctors/" + created.id())).body(created);
    }

    @GetMapping("/patients/{patientId}/appointments")
    @Operation(summary = "Consultas do paciente")
    public List<ScheduleDtos.AppointmentResponse> listByPatient(
            @PathVariable Long patientId,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return scheduleService.listByPatient(patientId, principal);
    }

    @GetMapping("/patients/{patientId}/appointments/next")
    @Operation(summary = "Proxima consulta do paciente")
    public ResponseEntity<ScheduleDtos.AppointmentResponse> next(
            @PathVariable Long patientId,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return scheduleService.next(patientId, principal)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.noContent().build());
    }

    @PostMapping("/appointments")
    @Operation(summary = "Agenda uma consulta")
    public ResponseEntity<ScheduleDtos.AppointmentResponse> schedule(
            @Valid @RequestBody ScheduleDtos.AppointmentRequest request,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        ScheduleDtos.AppointmentResponse created = scheduleService.schedule(request, principal);
        return ResponseEntity.created(URI.create("/api/v1/appointments/" + created.id())).body(created);
    }

    @PatchMapping("/appointments/{id}/status")
    @Operation(summary = "Atualiza o status da consulta")
    public ScheduleDtos.AppointmentResponse changeStatus(
            @PathVariable Long id,
            @RequestParam AppointmentStatus status,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return scheduleService.changeStatus(id, status, principal);
    }
}
