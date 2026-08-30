package com.smarthas.api.web.dto;

import com.smarthas.api.domain.Appointment;
import com.smarthas.api.domain.AppointmentStatus;
import com.smarthas.api.domain.Doctor;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

/** Contratos de teleconsulta e agenda. */
public final class ScheduleDtos {

    private ScheduleDtos() {
    }

    @Schema(description = "Cadastro de profissional")
    public record DoctorRequest(
            @NotBlank(message = "Informe o nome") String name,
            @NotBlank(message = "Informe a especialidade") String specialty,
            @NotBlank(message = "Informe o CRM") String crm,
            Boolean available) {
    }

    @Schema(description = "Profissional retornado pela API")
    public record DoctorResponse(
            Long id,
            String name,
            String initials,
            String specialty,
            String crm,
            boolean available) {

        public static DoctorResponse from(Doctor doctor) {
            return new DoctorResponse(
                    doctor.getId(),
                    doctor.getName(),
                    doctor.initials(),
                    doctor.getSpecialty(),
                    doctor.getCrm(),
                    doctor.isAvailable());
        }
    }

    @Schema(description = "Novo agendamento")
    public record AppointmentRequest(
            @NotNull(message = "Informe o paciente") Long patientId,
            @NotNull(message = "Informe o profissional") Long doctorId,
            @NotNull(message = "Informe a data e hora")
            @Future(message = "O agendamento deve ser no futuro")
            Instant scheduledAt,
            Boolean telemedicine,
            String notes) {
    }

    @Schema(description = "Consulta retornada pela API")
    public record AppointmentResponse(
            Long id,
            Long patientId,
            DoctorResponse doctor,
            Instant scheduledAt,
            boolean telemedicine,
            AppointmentStatus status,
            String notes) {

        public static AppointmentResponse from(Appointment appointment) {
            return new AppointmentResponse(
                    appointment.getId(),
                    appointment.getPatient().getId(),
                    DoctorResponse.from(appointment.getDoctor()),
                    appointment.getScheduledAt(),
                    appointment.isTelemedicine(),
                    appointment.getStatus(),
                    appointment.getNotes());
        }
    }
}
