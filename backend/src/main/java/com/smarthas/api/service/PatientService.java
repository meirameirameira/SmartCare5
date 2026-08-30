package com.smarthas.api.service;

import com.smarthas.api.domain.Patient;
import com.smarthas.api.repository.PatientRepository;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.web.dto.PatientDtos;
import com.smarthas.api.web.error.ResourceNotFoundException;
import java.util.List;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * CRUD de prontuarios e o ponto unico de autorizacao por posse do recurso.
 *
 * <p>Papeis de equipe leem qualquer paciente; um usuario paciente so acessa o
 * proprio prontuario. Essa checagem fica aqui (e nao nos controllers) para que
 * nenhum endpoint novo consiga esquece-la.</p>
 */
@Service
public class PatientService {

    private final PatientRepository patients;

    public PatientService(PatientRepository patients) {
        this.patients = patients;
    }

    /** Carrega o paciente garantindo que o usuario autenticado pode ve-lo. */
    @Transactional(readOnly = true)
    public Patient requireAccessible(Long patientId, AppUserPrincipal principal) {
        Patient patient = patients.findById(patientId)
                .orElseThrow(() -> new ResourceNotFoundException("Paciente", patientId));

        if (!principal.isStaff() && !patientId.equals(principal.getPatientId())) {
            throw new AccessDeniedException("Voce so pode acessar o seu proprio prontuario.");
        }
        return patient;
    }

    @Transactional(readOnly = true)
    public List<PatientDtos.PatientResponse> list(String search, int limit, AppUserPrincipal principal) {
        Pageable pageable = PageRequest.of(0, Math.min(Math.max(limit, 1), 100));

        // Paciente nao lista a base: recebe apenas o proprio registro.
        if (!principal.isStaff()) {
            if (principal.getPatientId() == null) {
                return List.of();
            }
            return List.of(PatientDtos.PatientResponse.from(
                    requireAccessible(principal.getPatientId(), principal)));
        }

        List<Patient> found = (search == null || search.isBlank())
                ? patients.findAllByOrderByCreatedAtDesc(pageable)
                : patients.searchByName(search.trim(), pageable);

        return found.stream().map(PatientDtos.PatientResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public PatientDtos.PatientResponse get(Long id, AppUserPrincipal principal) {
        return PatientDtos.PatientResponse.from(requireAccessible(id, principal));
    }

    @Transactional
    public PatientDtos.PatientResponse create(PatientDtos.PatientRequest request) {
        Patient patient = new Patient(
                request.name(),
                request.age(),
                request.conditions(),
                request.wearableConnected() == null || request.wearableConnected());
        return PatientDtos.PatientResponse.from(patients.save(patient));
    }

    @Transactional
    public PatientDtos.PatientResponse update(Long id, PatientDtos.PatientRequest request) {
        Patient patient = patients.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Paciente", id));

        patient.setName(request.name());
        patient.setAge(request.age());
        patient.setConditions(request.conditions());
        if (request.wearableConnected() != null) {
            patient.setWearableConnected(request.wearableConnected());
        }
        patient.touch();
        return PatientDtos.PatientResponse.from(patient);
    }

    @Transactional
    public void delete(Long id) {
        if (!patients.existsById(id)) {
            throw new ResourceNotFoundException("Paciente", id);
        }
        patients.deleteById(id);
    }

    @Transactional(readOnly = true)
    public List<PatientDtos.PatientResponse> recent(int limit) {
        return patients.findAllByOrderByCreatedAtDesc(PageRequest.of(0, limit)).stream()
                .map(PatientDtos.PatientResponse::from)
                .toList();
    }

    public long count() {
        return patients.count();
    }
}
