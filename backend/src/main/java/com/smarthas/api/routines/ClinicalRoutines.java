package com.smarthas.api.routines;

import com.smarthas.api.domain.Patient;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.web.dto.ReportDtos;
import java.util.List;

/**
 * Rotinas clinicas que podem rodar dentro do banco de dados.
 *
 * <p>Com o perfil {@code oracle} ativo, a implementacao
 * {@link PlsqlClinicalRoutines} delega cada operacao para as procedures e
 * functions PL/SQL de {@code database/oracle}, via JDBC. Nos demais perfis
 * (H2 em desenvolvimento e nos testes), {@link JavaClinicalRoutines} executa a
 * mesma regra em Java. Os servicos dependem apenas deste contrato, entao trocar
 * o motor e uma decisao de configuracao, nao de codigo.</p>
 *
 * <p>Todas as operacoes participam da transacao do chamador: uma leitura e os
 * alertas que ela gera sao confirmados juntos.</p>
 */
public interface ClinicalRoutines {

    /** Motor ativo: {@code ORACLE_PLSQL} ou {@code JAVA}. */
    String engine();

    /**
     * Avalia uma leitura ja gravada e abre os alertas cabiveis.
     *
     * @return quantidade de alertas criados
     */
    int generateAlerts(VitalReading reading);

    /** Consolida o relatorio do paciente no periodo (1 a 365 dias). */
    ReportDtos.PatientReportResponse consolidate(Patient patient, int periodDays);

    /** Consolida o relatorio de todos os pacientes no periodo. */
    List<ReportDtos.PatientReportResponse> consolidateAll(int periodDays);
}
