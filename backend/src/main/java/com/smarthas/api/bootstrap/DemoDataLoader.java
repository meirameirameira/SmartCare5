package com.smarthas.api.bootstrap;

import com.smarthas.api.domain.AppUser;
import com.smarthas.api.domain.Doctor;
import com.smarthas.api.domain.Patient;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.repository.AppUserRepository;
import com.smarthas.api.repository.AppointmentRepository;
import com.smarthas.api.repository.DeliveryOrderRepository;
import com.smarthas.api.repository.DoctorRepository;
import com.smarthas.api.repository.PatientRepository;
import com.smarthas.api.repository.VitalReadingRepository;
import com.smarthas.api.domain.Appointment;
import com.smarthas.api.domain.DeliveryOrder;
import com.smarthas.api.domain.DeliveryStatus;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Random;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/**
 * Carga inicial de demonstracao (apenas fora do perfil de producao).
 *
 * <p>Idempotente: se ja houver usuarios cadastrados, nada e recriado.</p>
 */
@Component
@Profile("!prod")
public class DemoDataLoader implements CommandLineRunner {

    private static final Logger log = LoggerFactory.getLogger(DemoDataLoader.class);

    private final AppUserRepository users;
    private final PatientRepository patients;
    private final VitalReadingRepository readings;
    private final DoctorRepository doctors;
    private final AppointmentRepository appointments;
    private final DeliveryOrderRepository deliveries;
    private final PasswordEncoder passwordEncoder;

    public DemoDataLoader(AppUserRepository users, PatientRepository patients, VitalReadingRepository readings,
                          DoctorRepository doctors, AppointmentRepository appointments,
                          DeliveryOrderRepository deliveries, PasswordEncoder passwordEncoder) {
        this.users = users;
        this.patients = patients;
        this.readings = readings;
        this.doctors = doctors;
        this.appointments = appointments;
        this.deliveries = deliveries;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (users.count() > 0) {
            log.info("Base ja populada - carga de demonstracao ignorada.");
            return;
        }

        Patient felipe = patients.save(new Patient("Felipe Meira", 22,
                List.of("Hipertensao leve", "Diabetes tipo 2"), true));
        Patient joao = patients.save(new Patient("Joao Silva", 68,
                List.of("Diabetes tipo 2"), true));

        users.save(new AppUser("admin@smarthas.com", passwordEncoder.encode("admin123"),
                "Administracao Smart HAS", AppUser.Role.ADMIN));
        users.save(new AppUser("enfermagem@smarthas.com", passwordEncoder.encode("enfermagem123"),
                "Enf. Carla Souza", AppUser.Role.PROFESSIONAL));

        AppUser patientUser = new AppUser("felipe@smarthas.com", passwordEncoder.encode("paciente123"),
                "Felipe Meira", AppUser.Role.PATIENT);
        patientUser.setPatient(felipe);
        users.save(patientUser);

        Doctor ricardo = doctors.save(new Doctor("Dr. Ricardo Alves", "Endocrinologia", "CRM/SP 87432", true));
        doctors.save(new Doctor("Dra. Ana Lima", "Clinica Geral", "CRM/SP 54210", true));
        doctors.save(new Doctor("Dr. Paulo Neto", "Cardiologia", "CRM/SP 33091", false));

        seedReadings(felipe, 40);
        seedReadings(joao, 20);

        DeliveryOrder order = deliveries.save(new DeliveryOrder(felipe, "SC-2026-0412",
                "Metformina 500mg (60cp) + Losartana 50mg (30cp)", "Farmacia Leroy Health", 3.2, 28));
        order.changeStatus(DeliveryStatus.PREPARING, null);
        order.changeStatus(DeliveryStatus.IN_TRANSIT,
                "IA detectou transito na Av. Paulista - rota alternativa ativa. ETA mantido.");

        DeliveryOrder entregue = deliveries.save(new DeliveryOrder(joao, "SC-2026-0388",
                "Insulina NPH (2 frascos)", "Drogaria Central", 1.8, 0));
        entregue.changeStatus(DeliveryStatus.PREPARING, null);
        entregue.changeStatus(DeliveryStatus.IN_TRANSIT, null);
        entregue.changeStatus(DeliveryStatus.DELIVERED, "Entrega concluida e confirmada pelo paciente.");

        appointments.save(new Appointment(felipe, ricardo,
                Instant.now().plus(6, ChronoUnit.HOURS), true, "Revisao trimestral de glicemia"));

        log.info("Carga de demonstracao concluida: {} pacientes, {} leituras, {} pedidos.",
                patients.count(), readings.count(), deliveries.count());
    }

    /** Gera um historico plausivel com passeio aleatorio em torno da linha de base. */
    private void seedReadings(Patient patient, int amount) {
        Random random = new Random(patient.getName().hashCode());
        int heartRate = 72;
        double spO2 = 98.5;
        int glucose = 104;
        int systolic = 118;
        int diastolic = 78;
        double temperature = 36.6;

        for (int i = amount; i > 0; i--) {
            heartRate = clamp(heartRate + random.nextInt(9) - 4, 58, 108);
            spO2 = clamp(spO2 + (random.nextDouble() - 0.5), 93.0, 100.0);
            glucose = clamp(glucose + random.nextInt(19) - 9, 74, 175);
            systolic = clamp(systolic + random.nextInt(9) - 4, 100, 145);
            diastolic = clamp(diastolic + random.nextInt(7) - 3, 62, 92);
            temperature = clamp(temperature + (random.nextDouble() - 0.5) * 0.3, 35.8, 37.6);

            readings.save(new VitalReading(patient, heartRate, round(spO2), glucose, systolic, diastolic,
                    round(temperature), Instant.now().minus(i * 4L, ChronoUnit.HOURS)));
        }
    }

    private static int clamp(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    private static double clamp(double value, double min, double max) {
        return Math.max(min, Math.min(max, value));
    }

    private static double round(double value) {
        return Math.round(value * 10.0) / 10.0;
    }
}
