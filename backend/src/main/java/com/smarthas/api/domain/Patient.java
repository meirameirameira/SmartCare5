package com.smarthas.api.domain;

import jakarta.persistence.CollectionTable;
import jakarta.persistence.Column;
import jakarta.persistence.ElementCollection;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;

/** Prontuario do paciente monitorado pelo Smart HAS. */
@Entity
@Table(name = "patient")
public class Patient {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, length = 120)
    private String name;

    @Column(nullable = false)
    private Integer age;

    @Column(name = "wearable_connected", nullable = false)
    private boolean wearableConnected = true;

    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "patient_condition", joinColumns = @JoinColumn(name = "patient_id"))
    @Column(name = "condition_name", length = 120)
    private List<String> conditions = new ArrayList<>();

    @Column(name = "created_at", nullable = false)
    private Instant createdAt = Instant.now();

    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt = Instant.now();

    protected Patient() {
        // exigido pelo JPA
    }

    public Patient(String name, Integer age, List<String> conditions, boolean wearableConnected) {
        this.name = name;
        this.age = age;
        this.conditions = conditions == null ? new ArrayList<>() : new ArrayList<>(conditions);
        this.wearableConnected = wearableConnected;
    }

    /** Iniciais usadas pelo avatar do app. */
    public String initials() {
        if (name == null || name.isBlank()) {
            return "--";
        }
        String[] parts = name.trim().split("\\s+");
        if (parts.length == 1) {
            return parts[0].substring(0, 1).toUpperCase();
        }
        return ("" + parts[0].charAt(0) + parts[parts.length - 1].charAt(0)).toUpperCase();
    }

    public void touch() {
        this.updatedAt = Instant.now();
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public Integer getAge() {
        return age;
    }

    public void setAge(Integer age) {
        this.age = age;
    }

    public boolean isWearableConnected() {
        return wearableConnected;
    }

    public void setWearableConnected(boolean wearableConnected) {
        this.wearableConnected = wearableConnected;
    }

    public List<String> getConditions() {
        return conditions;
    }

    public void setConditions(List<String> conditions) {
        this.conditions = conditions == null ? new ArrayList<>() : new ArrayList<>(conditions);
    }

    public Instant getCreatedAt() {
        return createdAt;
    }

    public Instant getUpdatedAt() {
        return updatedAt;
    }
}
