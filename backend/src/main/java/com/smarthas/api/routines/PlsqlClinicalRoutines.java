package com.smarthas.api.routines;

import com.smarthas.api.domain.Patient;
import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.web.dto.ReportDtos;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.time.OffsetDateTime;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Profile;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Component;

/**
 * Motor clinico executado no Oracle: a API apenas aciona as rotinas PL/SQL.
 *
 * <p>Fluxo de integracao: {@code REST -> Spring MVC -> servico -> esta classe
 * -> JDBC (CallableStatement) -> procedure Oracle}. O {@link JdbcTemplate}
 * usa o mesmo {@code DataSource} do JPA, entao a chamada roda na conexao e na
 * transacao abertas pelo {@code @Transactional} do servico — a leitura gravada
 * pelo Hibernate ja esta visivel para a procedure, e um ROLLBACK desfaz os dois.</p>
 *
 * <p>Erros de negocio levantados com {@code RAISE_APPLICATION_ERROR} viram
 * excecoes de dominio em {@link OracleErrorTranslator}, e chegam ao cliente com
 * o status HTTP correto.</p>
 */
@Component
@Profile("oracle")
public class PlsqlClinicalRoutines implements ClinicalRoutines {

    public static final String ENGINE = "ORACLE_PLSQL";

    static final String CALL_REGISTRAR_ALERTAS = "{call pkg_monitoramento.prc_registrar_alertas_leitura(?, ?)}";
    static final String CALL_CONSOLIDAR_RELATORIO = "{call pkg_relatorios.prc_consolidar_relatorio(?, ?, ?)}";

    static final String SELECT_REPORT = """
            select r.patient_id, p.name, r.period_days, r.generated_at, r.readings_count,
                   r.avg_heart_rate, r.avg_spo2, r.avg_glucose, r.avg_systolic, r.avg_diastolic,
                   r.avg_temperature, r.latest_score, r.average_score, r.risk_level,
                   r.glucose_time_in_range, r.open_alerts, r.urgent_alerts, r.alerts_in_period,
                   r.deliveries_total, r.deliveries_delivered, r.summary_text
              from patient_report r
              join patient p on p.id = r.patient_id
             where r.period_days = ?
            """;

    private static final Logger log = LoggerFactory.getLogger(PlsqlClinicalRoutines.class);

    private final JdbcTemplate jdbc;

    public PlsqlClinicalRoutines(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
        log.info("Motor clinico: Oracle PL/SQL (procedures e functions do banco).");
    }

    @Override
    public String engine() {
        return ENGINE;
    }

    /** {@code PKG_MONITORAMENTO.PRC_REGISTRAR_ALERTAS_LEITURA(p_reading_id IN, p_alertas_criados OUT)}. */
    @Override
    public int generateAlerts(VitalReading reading) {
        try {
            Integer created = jdbc.execute(CALL_REGISTRAR_ALERTAS, (CallableStatement cs) -> {
                cs.setLong(1, reading.getId());
                cs.registerOutParameter(2, Types.NUMERIC);
                cs.execute();
                return cs.getInt(2);
            });
            return created == null ? 0 : created;
        } catch (DataAccessException ex) {
            throw OracleErrorTranslator.translate(ex);
        }
    }

    @Override
    public ReportDtos.PatientReportResponse consolidate(Patient patient, int periodDays) {
        callConsolidation(patient.getId(), periodDays);
        List<ReportDtos.PatientReportResponse> found =
                jdbc.query(SELECT_REPORT + " and r.patient_id = ?", REPORT_MAPPER, periodDays, patient.getId());
        if (found.isEmpty()) {
            throw new IllegalStateException(
                    "PRC_CONSOLIDAR_RELATORIO nao gravou o relatorio do paciente " + patient.getId() + ".");
        }
        return found.get(0);
    }

    @Override
    public List<ReportDtos.PatientReportResponse> consolidateAll(int periodDays) {
        int processed = callConsolidation(null, periodDays);
        log.info("PRC_CONSOLIDAR_RELATORIO consolidou {} paciente(s) em {} dias.", processed, periodDays);
        return jdbc.query(SELECT_REPORT + " order by r.latest_score nulls last, p.name", REPORT_MAPPER, periodDays);
    }

    /**
     * {@code PKG_RELATORIOS.PRC_CONSOLIDAR_RELATORIO(p_patient_id IN, p_dias IN, p_processados OUT)}.
     * Um {@code patientId} nulo consolida todos os pacientes.
     */
    private int callConsolidation(Long patientId, int periodDays) {
        try {
            Integer processed = jdbc.execute(CALL_CONSOLIDAR_RELATORIO, (CallableStatement cs) -> {
                if (patientId == null) {
                    cs.setNull(1, Types.NUMERIC);
                } else {
                    cs.setLong(1, patientId);
                }
                cs.setInt(2, periodDays);
                cs.registerOutParameter(3, Types.NUMERIC);
                cs.execute();
                return cs.getInt(3);
            });
            return processed == null ? 0 : processed;
        } catch (DataAccessException ex) {
            throw OracleErrorTranslator.translate(ex);
        }
    }

    static final RowMapper<ReportDtos.PatientReportResponse> REPORT_MAPPER = (rs, rowNum) ->
            new ReportDtos.PatientReportResponse(
                    rs.getLong("patient_id"),
                    rs.getString("name"),
                    rs.getInt("period_days"),
                    rs.getObject("generated_at", OffsetDateTime.class).toInstant(),
                    rs.getInt("readings_count"),
                    new ReportDtos.VitalAverages(
                            decimal(rs, "avg_heart_rate"),
                            decimal(rs, "avg_spo2"),
                            decimal(rs, "avg_glucose"),
                            decimal(rs, "avg_systolic"),
                            decimal(rs, "avg_diastolic"),
                            decimal(rs, "avg_temperature")),
                    integer(rs, "latest_score"),
                    decimal(rs, "average_score"),
                    rs.getString("risk_level"),
                    decimal(rs, "glucose_time_in_range"),
                    rs.getInt("open_alerts"),
                    rs.getInt("urgent_alerts"),
                    rs.getInt("alerts_in_period"),
                    rs.getInt("deliveries_total"),
                    rs.getInt("deliveries_delivered"),
                    rs.getString("summary_text"),
                    ENGINE);

    /** NUMBER anulavel: {@code getDouble} devolveria 0 para NULL. */
    private static Double decimal(ResultSet rs, String column) throws SQLException {
        BigDecimal value = rs.getBigDecimal(column);
        return value == null ? null : value.doubleValue();
    }

    private static Integer integer(ResultSet rs, String column) throws SQLException {
        BigDecimal value = rs.getBigDecimal(column);
        return value == null ? null : value.intValue();
    }
}
