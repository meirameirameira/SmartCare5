package com.smarthas.api.domain;

/** Ciclo de vida de uma consulta (presencial ou teleconsulta). */
public enum AppointmentStatus {
    SCHEDULED,
    CONFIRMED,
    ACTIVE,
    COMPLETED,
    CANCELLED
}
