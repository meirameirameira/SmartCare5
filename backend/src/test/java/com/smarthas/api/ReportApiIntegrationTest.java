package com.smarthas.api;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.smarthas.api.repository.PatientRepository;
import java.util.Map;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;

/**
 * Contrato HTTP do relatorio consolidado (Fase 6).
 *
 * <p>Roda sobre H2 com o motor Java; o mesmo contrato e servido pelas rotinas
 * PL/SQL quando a API sobe com o perfil {@code oracle}.</p>
 */
@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@DisplayName("Relatorio clinico consolidado")
class ReportApiIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private PatientRepository patients;

    private String login(String email, String password) throws Exception {
        String body = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("email", email, "password", password))))
                .andExpect(status().isOk())
                .andReturn().getResponse().getContentAsString();
        return objectMapper.readTree(body).get("accessToken").asText();
    }

    private Long patientId(String name) {
        return patients.findAll().stream()
                .filter(p -> p.getName().equals(name))
                .findFirst().orElseThrow().getId();
    }

    @Test
    @DisplayName("paciente obtem o proprio relatorio com score, medias e resumo formatado")
    void patientReadsOwnReport() throws Exception {
        String token = login("felipe@smarthas.com", "paciente123");
        Long felipe = patientId("Felipe Meira");

        String body = mockMvc.perform(get("/api/v1/patients/" + felipe + "/report?periodDays=30")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.patientId").value(felipe))
                .andExpect(jsonPath("$.patientName").value("Felipe Meira"))
                .andExpect(jsonPath("$.periodDays").value(30))
                .andExpect(jsonPath("$.engine").value("JAVA"))
                .andReturn().getResponse().getContentAsString();

        JsonNode report = objectMapper.readTree(body);
        assertThat(report.get("readings").asInt()).isPositive();
        assertThat(report.get("latestScore").asInt()).isBetween(0, 100);
        assertThat(report.get("averages").get("heartRate").asDouble()).isBetween(40.0, 140.0);
        assertThat(report.get("glucoseTimeInRange").asDouble()).isBetween(0.0, 100.0);
        assertThat(report.get("deliveriesTotal").asInt()).isGreaterThanOrEqualTo(1);
        assertThat(report.get("summary").asText())
                .startsWith("Felipe Meira, 22 anos (Diabetes tipo 2, Hipertensao leve)")
                .contains("| Score atual: ")
                .contains("| Ultima leitura: ");
    }

    @Test
    @DisplayName("paciente nao acessa o relatorio de outro paciente")
    void patientCannotReadOtherReport() throws Exception {
        String token = login("felipe@smarthas.com", "paciente123");

        mockMvc.perform(get("/api/v1/patients/" + patientId("Joao Silva") + "/report")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("periodo fora de 1 a 365 dias e regra de negocio (422), como na procedure")
    void rejectsInvalidPeriod() throws Exception {
        String token = login("felipe@smarthas.com", "paciente123");

        mockMvc.perform(get("/api/v1/patients/" + patientId("Felipe Meira") + "/report?periodDays=0")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isUnprocessableEntity())
                .andExpect(jsonPath("$.message").value("Periodo invalido: informe entre 1 e 365 dias."));
    }

    @Test
    @DisplayName("relatorio de paciente com alerta urgente reflete os alertas abertos")
    void reportCountsOpenAlerts() throws Exception {
        String token = login("enfermagem@smarthas.com", "enfermagem123");

        // A carga de demonstracao registra para Joao uma leitura alterada que
        // passa pelo motor de regras e abre alertas.
        mockMvc.perform(get("/api/v1/patients/" + patientId("Joao Silva") + "/report?periodDays=7")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.openAlerts").value(org.hamcrest.Matchers.greaterThan(0)))
                .andExpect(jsonPath("$.alertsInPeriod").value(org.hamcrest.Matchers.greaterThan(0)))
                .andExpect(jsonPath("$.summary").value(org.hamcrest.Matchers.containsString("Alertas abertos:")));
    }

    @Test
    @DisplayName("equipe consolida todos os pacientes em lote")
    void staffConsolidatesAll() throws Exception {
        String token = login("admin@smarthas.com", "admin123");
        long total = patients.count();

        mockMvc.perform(post("/api/v1/reports/consolidation?periodDays=14")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.engine").value("JAVA"))
                .andExpect(jsonPath("$.periodDays").value(14))
                .andExpect(jsonPath("$.processed").value(total))
                .andExpect(jsonPath("$.reports.length()").value(total));
    }

    @Test
    @DisplayName("paciente nao dispara a consolidacao em lote")
    void patientCannotConsolidate() throws Exception {
        String token = login("felipe@smarthas.com", "paciente123");

        mockMvc.perform(post("/api/v1/reports/consolidation")
                        .header("Authorization", "Bearer " + token))
                .andExpect(status().isForbidden());
    }
}
