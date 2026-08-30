package com.smarthas.api.service;

import com.smarthas.api.domain.DeliveryOrder;
import com.smarthas.api.domain.DeliveryStatus;
import com.smarthas.api.domain.Patient;
import com.smarthas.api.repository.DeliveryOrderRepository;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.web.dto.DeliveryDtos;
import com.smarthas.api.web.error.BusinessRuleException;
import com.smarthas.api.web.error.ResourceNotFoundException;
import java.time.LocalDate;
import java.util.EnumMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ThreadLocalRandom;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Pedidos de medicamentos da camada AI Logistics Extension. */
@Service
public class DeliveryService {

    private final DeliveryOrderRepository orders;
    private final PatientService patientService;

    public DeliveryService(DeliveryOrderRepository orders, PatientService patientService) {
        this.orders = orders;
        this.patientService = patientService;
    }

    @Transactional(readOnly = true)
    public List<DeliveryDtos.DeliveryResponse> listByPatient(Long patientId, AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);
        return orders.findByPatientIdOrderByCreatedAtDesc(patientId).stream()
                .map(DeliveryDtos.DeliveryResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public DeliveryDtos.DeliveryResponse getByCode(String orderCode, AppUserPrincipal principal) {
        DeliveryOrder order = orders.findByOrderCode(orderCode)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido", orderCode));
        patientService.requireAccessible(order.getPatient().getId(), principal);
        return DeliveryDtos.DeliveryResponse.from(order);
    }

    @Transactional
    public DeliveryDtos.DeliveryResponse create(DeliveryDtos.DeliveryRequest request, AppUserPrincipal principal) {
        Patient patient = patientService.requireAccessible(request.patientId(), principal);

        DeliveryOrder order = new DeliveryOrder(
                patient,
                nextOrderCode(),
                request.description(),
                request.pharmacyName(),
                request.distanceKm(),
                request.etaMinutes());

        return DeliveryDtos.DeliveryResponse.from(orders.save(order));
    }

    /**
     * Avanca o status do pedido respeitando o fluxo logistico.
     *
     * <p>A transicao invalida (por exemplo, de CONFIRMED direto para DELIVERED,
     * ou reabrir um pedido cancelado) e rejeitada com HTTP 422 em vez de
     * corromper o historico.</p>
     */
    @Transactional
    public DeliveryDtos.DeliveryResponse changeStatus(Long orderId, DeliveryDtos.StatusChangeRequest request,
                                                      AppUserPrincipal principal) {
        DeliveryOrder order = orders.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Pedido", orderId));
        patientService.requireAccessible(order.getPatient().getId(), principal);

        DeliveryStatus current = order.getStatus();
        if (!current.canTransitionTo(request.status())) {
            throw new BusinessRuleException(
                    "Transicao invalida: o pedido esta em %s e nao pode ir para %s."
                            .formatted(current, request.status()));
        }

        order.changeStatus(request.status(), request.proactiveMessage());
        return DeliveryDtos.DeliveryResponse.from(order);
    }

    @Transactional
    public void delete(Long orderId) {
        if (!orders.existsById(orderId)) {
            throw new ResourceNotFoundException("Pedido", orderId);
        }
        orders.deleteById(orderId);
    }

    @Transactional(readOnly = true)
    public List<DeliveryDtos.DeliveryResponse> recent(int limit) {
        return orders.findRecentWithPatient(PageRequest.of(0, limit)).stream()
                .map(DeliveryDtos.DeliveryResponse::from)
                .toList();
    }

    /** Contagem por status agregada no banco, para o painel administrativo. */
    @Transactional(readOnly = true)
    public Map<String, Long> countByStatus() {
        Map<DeliveryStatus, Long> counts = new EnumMap<>(DeliveryStatus.class);
        for (Object[] row : orders.countGroupedByStatus()) {
            counts.put((DeliveryStatus) row[0], (Long) row[1]);
        }

        Map<String, Long> result = new LinkedHashMap<>();
        for (DeliveryStatus status : DeliveryStatus.values()) {
            result.put(status.name(), counts.getOrDefault(status, 0L));
        }
        return result;
    }

    public long countByStatus(DeliveryStatus status) {
        return orders.countByStatus(status);
    }

    private String nextOrderCode() {
        String code;
        do {
            code = "SC-%d-%04d".formatted(LocalDate.now().getYear(), ThreadLocalRandom.current().nextInt(1, 10000));
        } while (orders.existsByOrderCode(code));
        return code;
    }
}
