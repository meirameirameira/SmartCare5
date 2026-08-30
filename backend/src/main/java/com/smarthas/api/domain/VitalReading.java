package com.smarthas.api.domain;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Index;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import java.time.Instant;

/**
 * Leitura enviada pelo wearable / gateway IoT.
 *
 * <p>O indice composto (paciente, data) sustenta a consulta mais frequente da
 * API: "ultimas N leituras deste paciente em ordem decrescente".</p>
 */
@Entity
@Table(
        name = "vital_reading",
        indexes = @Index(name = "idx_vital_patient_measured", columnList = "patient_id, measured_at DESC")
)
public class VitalReading {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "patient_id", nullable = false)
    private Patient patient;

    @Column(name = "heart_rate", nullable = false)
    private Integer heartRate;

    @Column(name = "spo2", nullable = false)
    private Double spO2;

    @Column(name = "glucose_level", nullable = false)
    private Integer glucoseLevel;

    @Column(name = "bp_systolic", nullable = false)
    private Integer bpSystolic;

    @Column(name = "bp_diastolic", nullable = false)
    private Integer bpDiastolic;

    @Column(nullable = false)
    private Double temperature;

    @Column(name = "measured_at", nullable = false)
    private Instant measuredAt = Instant.now();

    protected VitalReading() {
        // exigido pelo JPA
    }

    public VitalReading(Patient patient, Integer heartRate, Double spO2, Integer glucoseLevel,
                        Integer bpSystolic, Integer bpDiastolic, Double temperature, Instant measuredAt) {
        this.patient = patient;
        this.heartRate = heartRate;
        this.spO2 = spO2;
        this.glucoseLevel = glucoseLevel;
        this.bpSystolic = bpSystolic;
        this.bpDiastolic = bpDiastolic;
        this.temperature = temperature;
        this.measuredAt = measuredAt == null ? Instant.now() : measuredAt;
    }

    public Long getId() {
        return id;
    }

    public Patient getPatient() {
        return patient;
    }

    public Integer getHeartRate() {
        return heartRate;
    }

    public Double getSpO2() {
        return spO2;
    }

    public Integer getGlucoseLevel() {
        return glucoseLevel;
    }

    public Integer getBpSystolic() {
        return bpSystolic;
    }

    public Integer getBpDiastolic() {
        return bpDiastolic;
    }

    public Double getTemperature() {
        return temperature;
    }

    public Instant getMeasuredAt() {
        return measuredAt;
    }
}
