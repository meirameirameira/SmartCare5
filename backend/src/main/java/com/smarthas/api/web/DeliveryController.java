package com.smarthas.api.web;

import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.service.DeliveryService;
import com.smarthas.api.web.dto.DeliveryDtos;
import io.swagger.v3.oas.annotations.Operation;
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
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** Entregas de medicamentos (AI Logistics Extension). */
@RestController
@RequestMapping("/api/v1")
@SecurityRequirement(name = "bearerAuth")
@Tag(name = "Entregas", description = "Pedidos de medicamentos e rastreio da rota")
public class DeliveryController {

    private final DeliveryService deliveryService;

    public DeliveryController(DeliveryService deliveryService) {
        this.deliveryService = deliveryService;
    }

    @GetMapping("/patients/{patientId}/deliveries")
    @Operation(summary = "Lista os pedidos do paciente")
    public List<DeliveryDtos.DeliveryResponse> listByPatient(
            @PathVariable Long patientId,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return deliveryService.listByPatient(patientId, principal);
    }

    @GetMapping("/deliveries/{orderCode}")
    @Operation(summary = "Rastreia um pedido pelo codigo")
    public DeliveryDtos.DeliveryResponse track(@PathVariable String orderCode,
                                               @AuthenticationPrincipal AppUserPrincipal principal) {
        return deliveryService.getByCode(orderCode, principal);
    }

    @PostMapping("/deliveries")
    @PreAuthorize("hasAnyRole('PROFESSIONAL','ADMIN')")
    @Operation(summary = "Cria um pedido de medicamentos")
    public ResponseEntity<DeliveryDtos.DeliveryResponse> create(
            @Valid @RequestBody DeliveryDtos.DeliveryRequest request,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        DeliveryDtos.DeliveryResponse created = deliveryService.create(request, principal);
        return ResponseEntity.created(URI.create("/api/v1/deliveries/" + created.orderCode())).body(created);
    }

    @PatchMapping("/deliveries/{id}/status")
    @Operation(summary = "Avanca o status do pedido")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Status atualizado"),
            @ApiResponse(responseCode = "422", description = "Transicao de status invalida")
    })
    public DeliveryDtos.DeliveryResponse changeStatus(
            @PathVariable Long id,
            @Valid @RequestBody DeliveryDtos.StatusChangeRequest request,
            @AuthenticationPrincipal AppUserPrincipal principal) {
        return deliveryService.changeStatus(id, request, principal);
    }

    @DeleteMapping("/deliveries/{id}")
    @PreAuthorize("hasRole('ADMIN')")
    @Operation(summary = "Remove um pedido")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        deliveryService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
