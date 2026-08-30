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

/** Alerta clinico gerado pelo motor de regras ou registrado por um profissional. */
@Entity
@Table(
        name = "health_alert",
        indexes = @Index(name = "idx_alert_patient_ack", columnList = "patient_id, acknowledged")
)
public class HealthAlert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AlertType type;

    @Column(nullable = false, length = 160)
    private String title;

    @Column(nullable = false, length = 500)
    private String description;

    /** Metrica que originou o alerta, quando gerado automaticamente. */
    @Column(length = 60)
    private String metric;

    @Column(nullable = false)
    private boolean acknowledged = false;

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "acknowledged_at")
    private Instant acknowledgedAt;

    protected HealthAlert() {
        // exigido pelo JPA
    }

    public HealthAlert(Patient patient, AlertType type, String title, String description, String metric) {
        this.patient = patient;
        this.type = type;
        this.title = title;
        this.description = description;
        this.metric = metric;
    }

    /** Marca o alerta como tratado; idempotente por design. */
    public void acknowledge() {
        if (!acknowledged) {
            this.acknowledged = true;
            this.acknowledgedAt = Instant.now();
        }
    }

    public Long getId() {
        return id;
    }

    public Patient getPatient() {
        return patient;
    }

    public AlertType getType() {
        return type;
    }

    public void setType(AlertType type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getMetric() {
        return metric;
    }

    public boolean isAcknowledged() {
        return acknowledged;
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getAcknowledgedAt() {
        return acknowledgedAt;
    }
}
