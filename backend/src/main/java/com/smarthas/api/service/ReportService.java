package com.smarthas.api.service;

import com.smarthas.api.domain.Patient;
import com.smarthas.api.routines.ClinicalRoutines;
import com.smarthas.api.security.AppUserPrincipal;
import com.smarthas.api.web.dto.ReportDtos;
import com.smarthas.api.web.error.BusinessRuleException;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Relatorio clinico consolidado (score, medias, tempo na faixa, alertas e
 * consumo de medicamentos).
 *
 * <p>O calculo e delegado a {@link ClinicalRoutines}: no Oracle, a procedure
 * {@code PRC_CONSOLIDAR_RELATORIO} grava o snapshot em {@code PATIENT_REPORT}
 * e a API apenas le o resultado. A transacao nao e somente-leitura porque a
 * consolidacao atualiza esse snapshot — operacao idempotente, que pode ser
 * repetida sem efeito colateral.</p>
 */
@Service
public class ReportService {

    public static final int MIN_PERIOD = 1;
    public static final int MAX_PERIOD = 365;

    private final ClinicalRoutines clinicalRoutines;
    private final PatientService patientService;

    public ReportService(ClinicalRoutines clinicalRoutines, PatientService patientService) {
        this.clinicalRoutines = clinicalRoutines;
        this.patientService = patientService;
    }

    @Transactional
    public ReportDtos.PatientReportResponse patientReport(Long patientId, int periodDays,
                                                          AppUserPrincipal principal) {
        Patient patient = patientService.requireAccessible(patientId, principal);
        return clinicalRoutines.consolidate(patient, validPeriod(periodDays));
    }

    /** Consolidacao em lote, acionada pela equipe no painel administrativo. */
    @Transactional
    public ReportDtos.ConsolidationResponse consolidateAll(int periodDays) {
        int days = validPeriod(periodDays);
        List<ReportDtos.PatientReportResponse> reports = clinicalRoutines.consolidateAll(days);
        return new ReportDtos.ConsolidationResponse(clinicalRoutines.engine(), days, reports.size(), reports);
    }

    /** Mesma regra da procedure (erro -20003): fora da faixa e erro, nao ajuste silencioso. */
    private static int validPeriod(int periodDays) {
        if (periodDays < MIN_PERIOD || periodDays > MAX_PERIOD) {
            throw new BusinessRuleException("Periodo invalido: informe entre 1 e 365 dias.");
        }
        return periodDays;
    }
}
