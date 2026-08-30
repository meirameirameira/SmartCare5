package com.smarthas.api.service;

import com.smarthas.api.domain.Appointment;
import com.smarthas.api.domain.AppointmentStatus;
import com.smarthas.api.domain.Doctor;
import com.smarthas.api.domain.Patient;
import com.smarthas.api.repository.AppointmentRepository;
import com.smarthas.api.repository.DoctorRepository;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.web.dto.ScheduleDtos;
import com.smarthas.api.web.error.BusinessRuleException;
import com.smarthas.api.web.error.ResourceNotFoundException;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** Agenda de teleconsultas e cadastro de profissionais. */
@Service
public class ScheduleService {

    private final DoctorRepository doctors;
    private final AppointmentRepository appointments;
    private final PatientService patientService;

    public ScheduleService(DoctorRepository doctors, AppointmentRepository appointments,
                           PatientService patientService) {
        this.doctors = doctors;
        this.appointments = appointments;
        this.patientService = patientService;
    }

    @Transactional(readOnly = true)
    public List<ScheduleDtos.DoctorResponse> listDoctors(String specialty, boolean onlyAvailable) {
        List<Doctor> found;
        if (specialty != null && !specialty.isBlank()) {
            found = doctors.findBySpecialtyIgnoreCaseOrderByNameAsc(specialty.trim());
        } else if (onlyAvailable) {
            found = doctors.findByAvailableTrueOrderByNameAsc();
        } else {
            found = doctors.findAll();
        }
        return found.stream().map(ScheduleDtos.DoctorResponse::from).toList();
    }

    @Transactional
    public ScheduleDtos.DoctorResponse createDoctor(ScheduleDtos.DoctorRequest request) {
        doctors.findByCrm(request.crm()).ifPresent(existing -> {
            throw new BusinessRuleException("Ja existe um profissional cadastrado com o CRM informado.");
        });

        Doctor doctor = new Doctor(request.name(), request.specialty(), request.crm(),
                request.available() == null || request.available());
        return ScheduleDtos.DoctorResponse.from(doctors.save(doctor));
    }

    @Transactional(readOnly = true)
    public List<ScheduleDtos.AppointmentResponse> listByPatient(Long patientId, AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);
        return appointments.findByPatientIdOrderByScheduledAtAsc(patientId).stream()
                .map(ScheduleDtos.AppointmentResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public Optional<ScheduleDtos.AppointmentResponse> next(Long patientId, AppUserPrincipal principal) {
        patientService.requireAccessible(patientId, principal);
        return appointments
                .findFirstByPatientIdAndScheduledAtAfterAndStatusNotOrderByScheduledAtAsc(
                        patientId, Instant.now(), AppointmentStatus.CANCELLED)
                .map(ScheduleDtos.AppointmentResponse::from);
    }

    /** Agenda uma consulta validando disponibilidade e conflito de horario. */
    @Transactional
    public ScheduleDtos.AppointmentResponse schedule(ScheduleDtos.AppointmentRequest request,
                                                     AppUserPrincipal principal) {
        Patient patient = patientService.requireAccessible(request.patientId(), principal);

        Doctor doctor = doctors.findById(request.doctorId())
                .orElseThrow(() -> new ResourceNotFoundException("Profissional", request.doctorId()));

        if (!doctor.isAvailable()) {
            throw new BusinessRuleException("O profissional selecionado nao esta disponivel para agendamento.");
        }

        if (appointments.existsByDoctorIdAndScheduledAtAndStatusNot(
                doctor.getId(), request.scheduledAt(), AppointmentStatus.CANCELLED)) {
            throw new BusinessRuleException("O profissional ja possui uma consulta neste horario.");
        }

        Appointment appointment = new Appointment(
                patient,
                doctor,
                request.scheduledAt(),
                request.telemedicine() == null || request.telemedicine(),
                request.notes());

        return ScheduleDtos.AppointmentResponse.from(appointments.save(appointment));
    }

    @Transactional
    public ScheduleDtos.AppointmentResponse changeStatus(Long appointmentId, AppointmentStatus status,
                                                         AppUserPrincipal principal) {
        Appointment appointment = appointments.findById(appointmentId)
                .orElseThrow(() -> new ResourceNotFoundException("Consulta", appointmentId));
        patientService.requireAccessible(appointment.getPatient().getId(), principal);

        if (appointment.getStatus() == AppointmentStatus.COMPLETED) {
            throw new BusinessRuleException("Uma consulta concluida nao pode mudar de status.");
        }

        appointment.setStatus(status);
        return ScheduleDtos.AppointmentResponse.from(appointment);
    }

    public long countUpcoming() {
        return appointments.countByScheduledAtAfterAndStatusNot(Instant.now(), AppointmentStatus.CANCELLED);
    }
}
