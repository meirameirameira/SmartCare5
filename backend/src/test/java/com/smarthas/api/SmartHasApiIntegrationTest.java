package com.smarthas.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smarthas.api.domain.DeliveryStatus;
import com.smarthas.api.repository.DeliveryOrderRepository;
import com.smarthas.api.repository.PatientRepository;
import java.util.Map;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Testes de integracao da API: sobem o contexto completo (seguranca, JPA,
 * validacao e MVC) e exercitam os fluxos pelo protocolo HTTP real.
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("API Smart HAS")
class SmartHasApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PatientRepository patients;

    @Autowired
    private DeliveryOrderRepository deliveries;

    private static String adminToken;
    private static String patientToken;

    @BeforeAll
    static void resetTokens() {
        adminToken = null;
        patientToken = null;
    }

    private String login(String email, String password) throws Exception {
        String body = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email, "password", password))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        return objectMapper.readTree(body).get("accessToken").asText();
    }

    private String adminToken() throws Exception {
        if (adminToken == null) {
            adminToken = login("admin@smarthas.com", "admin123");
        }
        return adminToken;
    }

    private String patientToken() throws Exception {
        if (patientToken == null) {
            patientToken = login("felipe@smarthas.com", "paciente123");
        }
        return patientToken;
    }

    private Long felipeId() {
        return patients.findAll().stream()
                .filter(p -> p.getName().equals("Felipe Meira"))
                .findFirst().orElseThrow().getId();
    }

    private Long joaoId() {
        return patients.findAll().stream()
                .filter(p -> p.getName().equals("Joao Silva"))
                .findFirst().orElseThrow().getId();
    }

    // ─── Autenticacao e autorizacao ───────────────────────────────────────────

    @Test
    @DisplayName("login valido devolve token JWT e dados do usuario")
    void loginReturnsToken() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                Map.of("email", "admin@smarthas.com", "password", "admin123"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.user.role").value("ADMIN"));
    }

    @Test
    @DisplayName("senha incorreta devolve 401 sem revelar se o e-mail existe")
    void loginWithWrongPassword() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                Map.of("email", "admin@smarthas.com", "password", "senha-errada"))))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("E-mail ou senha incorretos."));
    }

    @Test
    @DisplayName("e-mail mal formatado e barrado pela validacao")
    void loginValidation() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                Map.of("email", "nao-e-email", "password", ""))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors").isArray());
    }

    @Test
    @DisplayName("requisicao sem token recebe 401 em JSON")
    void requiresAuthentication() throws Exception {
        mockMvc.perform(get("/api/v1/patients"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.error").value("Nao autenticado"));
    }

    @Test
    @DisplayName("paciente nao acessa o prontuario de outro paciente")
    void patientCannotReadOtherPatient() throws Exception {
        mockMvc.perform(get("/api/v1/patients/" + joaoId())
                        .header("Authorization", "Bearer " + patientToken()))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("paciente le o proprio prontuario")
    void patientReadsOwnRecord() throws Exception {
        mockMvc.perform(get("/api/v1/patients/" + felipeId())
                        .header("Authorization", "Bearer " + patientToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Felipe Meira"))
                .andExpect(jsonPath("$.initials").value("FM"));
    }

    @Test
    @DisplayName("paciente nao cria prontuarios (escrita e da equipe)")
    void patientCannotCreatePatients() throws Exception {
        mockMvc.perform(post("/api/v1/patients")
                        .header("Authorization", "Bearer " + patientToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                Map.of("name", "Teste", "age", 30))))
                .andExpect(status().isForbidden());
    }

    // ─── CRUD e validacao ─────────────────────────────────────────────────────

    @Test
    @DisplayName("equipe cria, atualiza e remove um prontuario")
    void crudPatient() throws Exception {
        String created = mockMvc.perform(post("/api/v1/patients")
                        .header("Authorization", "Bearer " + adminToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "name", "Maria Souza",
                                "age", 71,
                                "conditions", java.util.List.of("Hipertensao"),
                                "wearableConnected", true))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.initials").value("MS"))
                .andReturn().getResponse().getContentAsString();

        long id = objectMapper.readTree(created).get("id").asLong();

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .put("/api/v1/patients/" + id)
                        .header("Authorization", "Bearer " + adminToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "name", "Maria Souza Lima",
                                "age", 72,
                                "conditions", java.util.List.of("Hipertensao", "Artrite")))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.age").value(72))
                .andExpect(jsonPath("$.conditions.length()").value(2));

        mockMvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders
                        .delete("/api/v1/patients/" + id)
                        .header("Authorization", "Bearer " + adminToken()))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/v1/patients/" + id)
                        .header("Authorization", "Bearer " + adminToken()))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.error").value("Recurso nao encontrado"));
    }

    @Test
    @DisplayName("leitura fora do range fisiologico e rejeitada com os campos invalidos")
    void rejectsImpossibleVitalReading() throws Exception {
        mockMvc.perform(post("/api/v1/patients/" + felipeId() + "/vitals")
                        .header("Authorization", "Bearer " + patientToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "heartRate", 900,
                                "spO2", 140.0,
                                "glucoseLevel", 104,
                                "bpSystolic", 118,
                                "bpDiastolic", 78,
                                "temperature", 36.6))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Dados invalidos"))
                .andExpect(jsonPath("$.fieldErrors.length()").value(2));
    }

    // ─── Regras de negocio ────────────────────────────────────────────────────

    @Test
    @DisplayName("leitura critica gera alerta urgente e derruba o score")
    void criticalReadingGeneratesAlert() throws Exception {
        Long patientId = felipeId();

        mockMvc.perform(post("/api/v1/patients/" + patientId + "/vitals")
                        .header("Authorization", "Bearer " + patientToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "heartRate", 72,
                                "spO2", 84.0,
                                "glucoseLevel", 104,
                                "bpSystolic", 118,
                                "bpDiastolic", 78,
                                "temperature", 36.6))))
                .andExpect(status().isCreated());

        String alerts = mockMvc.perform(get("/api/v1/patients/" + patientId + "/alerts?onlyOpen=true")
                        .header("Authorization", "Bearer " + patientToken()))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();

        JsonNode urgent = objectMapper.readTree(alerts);
        assertThat(urgent.isArray()).isTrue();
        assertThat(urgent.toString()).contains("URGENT").contains("SpO2");

        mockMvc.perform(get("/api/v1/patients/" + patientId + "/health-score")
                        .header("Authorization", "Bearer " + patientToken()))
                .andExpect(status().isOk())
                // SpO2 critica desconta os 22 pontos do peso da metrica.
                .andExpect(jsonPath("$.score").value(78))
                .andExpect(jsonPath("$.label").value("BOM"))
                .andExpect(jsonPath("$.penalties.SpO2").value(22));
    }

    @Test
    @DisplayName("valores decimais saem com ponto, independente do locale do servidor")
    void decimalValuesUseDotSeparator() throws Exception {
        mockMvc.perform(get("/api/v1/patients/" + felipeId() + "/health-score")
                        .header("Authorization", "Bearer " + patientToken()))
                .andExpect(status().isOk())
                // O cliente Dart faz double.parse deste campo: virgula quebraria o parse.
                .andExpect(jsonPath("$.evaluations[1].value").value(
                        org.hamcrest.Matchers.matchesPattern("\\d+\\.\\d")));
    }

    @Test
    @DisplayName("transicao de status invalida da entrega devolve 422")
    void rejectsInvalidDeliveryTransition() throws Exception {
        Long orderId = deliveries.findByOrderCode("SC-2026-0388").orElseThrow().getId();

        // O pedido ja esta DELIVERED: nao pode voltar para a rota.
        mockMvc.perform(patch("/api/v1/deliveries/" + orderId + "/status")
                        .header("Authorization", "Bearer " + adminToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(
                                Map.of("status", DeliveryStatus.IN_TRANSIT.name()))))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.error").value("Regra de negocio"));
    }

    @Test
    @DisplayName("entrega avanca um passo por vez e monta a trilha do app")
    void advancesDeliveryStepByStep() throws Exception {
        String created = mockMvc.perform(post("/api/v1/deliveries")
                        .header("Authorization", "Bearer " + adminToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "patientId", felipeId(),
                                "description", "Dipirona 500mg (20cp)",
                                "pharmacyName", "Farmacia Central",
                                "distanceKm", 2.4,
                                "etaMinutes", 35))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.steps.length()").value(4))
                .andReturn().getResponse().getContentAsString();

        long id = objectMapper.readTree(created).get("id").asLong();

        mockMvc.perform(patch("/api/v1/deliveries/" + id + "/status")
                        .header("Authorization", "Bearer " + adminToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("status", "PREPARING"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.currentStep").value(1))
                .andExpect(jsonPath("$.steps[0].done").value(true))
                .andExpect(jsonPath("$.steps[1].current").value(true));
    }

    @Test
    @DisplayName("agendamento no passado e recusado pela validacao")
    void rejectsPastAppointment() throws Exception {
        mockMvc.perform(post("/api/v1/appointments")
                        .header("Authorization", "Bearer " + adminToken())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "patientId", felipeId(),
                                "doctorId", 1,
                                "scheduledAt", "2020-01-01T10:00:00Z"))))
                .andExpect(status().isBadRequest());
    }

    // ─── Analytics, painel e documentacao ─────────────────────────────────────

    @Test
    @DisplayName("analytics do paciente retorna series e insights")
    void patientAnalytics() throws Exception {
        mockMvc.perform(get("/api/v1/analytics/patients/" + felipeId() + "?periodDays=7")
                        .header("Authorization", "Bearer " + patientToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.metrics.length()").value(4))
                .andExpect(jsonPath("$.insights").isArray())
                .andExpect(jsonPath("$.periodDays").value(7));
    }

    @Test
    @DisplayName("visao geral da operacao e restrita a equipe")
    void overviewRequiresStaff() throws Exception {
        mockMvc.perform(get("/api/v1/analytics/overview")
                        .header("Authorization", "Bearer " + patientToken()))
                .andExpect(status().isForbidden());

        mockMvc.perform(get("/api/v1/analytics/overview")
                        .header("Authorization", "Bearer " + adminToken()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalPatients").isNumber())
                .andExpect(jsonPath("$.deliveriesByStatus").isMap());
    }

    @Test
    @DisplayName("painel Thymeleaf e renderizado no servidor")
    void serverSidePanelRenders() throws Exception {
        mockMvc.perform(get("/painel"))
                .andExpect(status().isOk())
                .andExpect(content().contentTypeCompatibleWith(MediaType.TEXT_HTML))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Painel")));
    }

    @Test
    @DisplayName("documentacao OpenAPI e publicada")
    void openApiIsPublished() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.info.title").value("Smart HAS / SmartCare 5.0 - API REST"))
                .andExpect(jsonPath("$.paths['/api/v1/auth/login']").exists());
    }
}
