package com.smarthas.api.repository;

import com.smarthas.api.domain.Appointment;
import com.smarthas.api.domain.AppointmentStatus;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppointmentRepository extends JpaRepository<Appointment, Long> {

    List<Appointment> findByPatientIdOrderByScheduledAtAsc(Long patientId);

    /** Proxima consulta futura ainda ativa do paciente. */
    Optional<Appointment> findFirstByPatientIdAndScheduledAtAfterAndStatusNotOrderByScheduledAtAsc(
            Long patientId, Instant from, AppointmentStatus excluded);

    long countByScheduledAtAfterAndStatusNot(Instant from, AppointmentStatus excluded);

    /** Impede agendar dois horarios conflitantes para o mesmo profissional. */
    boolean existsByDoctorIdAndScheduledAtAndStatusNot(Long doctorId, Instant scheduledAt, AppointmentStatus excluded);
}
