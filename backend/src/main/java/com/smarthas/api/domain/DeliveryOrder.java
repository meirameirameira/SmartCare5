package com.smarthas.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/** Pedido de medicamentos rastreado pela camada AI Logistics Extension. */
@Entity
@Table(
        name = "delivery_order",
        indexes = @Index(name = "idx_delivery_patient_status", columnList = "patient_id, status")
)
public class DeliveryOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @Column(name = "order_code", nullable = false, unique = true, length = 40)
    private String orderCode;

    @Column(nullable = false, length = 300)
    private String description;

    @Column(name = "pharmacy_name", nullable = false, length = 160)
    private String pharmacyName;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private DeliveryStatus status = DeliveryStatus.CONFIRMED;

    @Column(name = "distance_km", nullable = false)
    private Double distanceKm;

    @Column(name = "eta_minutes")
    private Integer etaMinutes;

    /** Mensagem proativa produzida pela IA de logistica (ex.: desvio de rota). */
    @Column(name = "proactive_message", length = 300)
    private String proactiveMessage;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    protected DeliveryOrder() {
        // exigido pelo JPA
    }

    public DeliveryOrder(Patient patient, String orderCode, String description, String pharmacyName,
                         Double distanceKm, Integer etaMinutes) {
        this.patient = patient;
        this.orderCode = orderCode;
        this.description = description;
        this.pharmacyName = pharmacyName;
        this.distanceKm = distanceKm;
        this.etaMinutes = etaMinutes;
    }

    /** Passo atual na trilha de 4 etapas exibida no app. */
    public int currentStep() {
        return Math.max(status.step(), 0);
    }

    public void changeStatus(DeliveryStatus next, String proactiveMessage) {
        this.status = next;
        if (proactiveMessage != null) {
            this.proactiveMessage = proactiveMessage;
        }
        if (next == DeliveryStatus.DELIVERED || next == DeliveryStatus.CANCELLED) {
            this.etaMinutes = 0;
        }
        this.updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public Patient getPatient() {
        return patient;
    }

    public String getOrderCode() {
        return orderCode;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getPharmacyName() {
        return pharmacyName;
    }

    public void setPharmacyName(String pharmacyName) {
        this.pharmacyName = pharmacyName;
    }

    public DeliveryStatus getStatus() {
        return status;
    }

    public Double getDistanceKm() {
        return distanceKm;
    }

    public void setDistanceKm(Double distanceKm) {
        this.distanceKm = distanceKm;
    }

    public Integer getEtaMinutes() {
        return etaMinutes;
    }

    public void setEtaMinutes(Integer etaMinutes) {
        this.etaMinutes = etaMinutes;
    }

    public String getProactiveMessage() {
        return proactiveMessage;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
