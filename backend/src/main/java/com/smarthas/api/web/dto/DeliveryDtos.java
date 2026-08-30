package com.smarthas.api.web.dto;

import com.smarthas.api.domain.DeliveryOrder;
import com.smarthas.api.domain.DeliveryStatus;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.PositiveOrZero;
import java.time.Instant;
import java.util.List;

/** Contratos da camada AI Logistics Extension. */
public final class DeliveryDtos {

    private DeliveryDtos() {
    }

    @Schema(description = "Novo pedido de medicamentos")
    public record DeliveryRequest(
            @NotNull(message = "Informe o paciente")
            Long patientId,

            @NotBlank(message = "Descreva os itens do pedido")
            String description,

            @NotBlank(message = "Informe a farmacia")
            String pharmacyName,

            @NotNull(message = "Informe a distancia")
            @Positive(message = "Distancia deve ser maior que zero")
            Double distanceKm,

            @PositiveOrZero(message = "ETA nao pode ser negativo")
            Integer etaMinutes) {
    }

    @Schema(description = "Mudanca de status do pedido")
    public record StatusChangeRequest(
            @NotNull(message = "Informe o novo status")
            DeliveryStatus status,

            @Schema(description = "Mensagem proativa da IA de logistica", nullable = true)
            String proactiveMessage) {
    }

    @Schema(description = "Etapa da trilha de entrega")
    public record DeliveryStep(String label, boolean done, boolean current) {
    }

    @Schema(description = "Pedido retornado pela API")
    public record DeliveryResponse(
            Long id,
            String orderCode,
            Long patientId,
            String patientName,
            String description,
            String pharmacyName,
            DeliveryStatus status,
            int currentStep,
            List<DeliveryStep> steps,
            Double distanceKm,
            Integer etaMinutes,
            String proactiveMessage,
            Instant updatedAt) {

        private static final List<String> STEP_LABELS =
                List.of("Confirmado", "Separado", "Em rota", "Entregue");

        public static DeliveryResponse from(DeliveryOrder order) {
            int current = order.currentStep();
            List<DeliveryStep> steps = java.util.stream.IntStream.range(0, STEP_LABELS.size())
                    .mapToObj(i -> new DeliveryStep(STEP_LABELS.get(i), i < current, i == current))
                    .toList();

            return new DeliveryResponse(
                    order.getId(),
                    order.getOrderCode(),
                    order.getPatient().getId(),
                    order.getPatient().getName(),
                    order.getDescription(),
                    order.getPharmacyName(),
                    order.getStatus(),
                    current,
                    steps,
                    order.getDistanceKm(),
                    order.getEtaMinutes(),
                    order.getProactiveMessage(),
                    order.getUpdatedAt());
        }
    }
}
