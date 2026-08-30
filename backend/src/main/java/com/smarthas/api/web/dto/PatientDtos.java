package com.smarthas.api.web.dto;

import com.smarthas.api.domain.Patient;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;

/** Contratos do prontuario do paciente. */
public final class PatientDtos {

    private PatientDtos() {
    }

    @Schema(description = "Dados para criar ou atualizar um prontuario")
    public record PatientRequest(
            @NotBlank(message = "Informe o nome do paciente")
            @Size(max = 120, message = "Nome muito longo")
            String name,

            @NotNull(message = "Informe a idade")
            @Min(value = 0, message = "Idade invalida")
            @Max(value = 130, message = "Idade invalida")
            Integer age,

            @Schema(description = "Condicoes cronicas monitoradas")
            List<String> conditions,

            Boolean wearableConnected) {
    }

    @Schema(description = "Prontuario retornado pela API")
    public record PatientResponse(
            Long id,
            String name,
            String initials,
            Integer age,
            List<String> conditions,
            boolean wearableConnected,
            Instant updatedAt) {

        public static PatientResponse from(Patient patient) {
            return new PatientResponse(
                    patient.getId(),
                    patient.getName(),
                    patient.initials(),
                    patient.getAge(),
                    List.copyOf(patient.getConditions()),
                    patient.isWearableConnected(),
                    patient.getUpdatedAt());
        }
    }
}
