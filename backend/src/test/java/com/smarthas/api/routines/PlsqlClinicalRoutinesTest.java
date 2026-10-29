package com.smarthas.api.routines;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.smarthas.api.domain.VitalReading;
import com.smarthas.api.web.error.ResourceNotFoundException;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.UncategorizedSQLException;
import org.springframework.jdbc.core.CallableStatementCallback;
import org.springframework.jdbc.core.JdbcTemplate;

/**
 * Verifica a ponte JDBC com as procedures sem precisar de um Oracle no ar:
 * o {@link JdbcTemplate} e o {@link CallableStatement} sao simulados e o teste
 * confere a chamada, o binding dos parametros IN e a leitura dos OUT.
 */
@DisplayName("Integracao JDBC com as procedures PL/SQL")
class PlsqlClinicalRoutinesTest {

    private JdbcTemplate jdbc;
    private CallableStatement statement;
    private PlsqlClinicalRoutines routines;

    @BeforeEach
    @SuppressWarnings("unchecked")
    void setUp() throws Exception {
        jdbc = mock(JdbcTemplate.class);
        statement = mock(CallableStatement.class);
        routines = new PlsqlClinicalRoutines(jdbc);

        // Executa o callback de verdade contra o CallableStatement simulado.
        when(jdbc.execute(anyString(), any(CallableStatementCallback.class)))
                .thenAnswer(call -> ((CallableStatementCallback<Object>) call.getArgument(1)).doInCallableStatement(statement));
    }

    private static VitalReading readingWithId(long id) {
        VitalReading reading = mock(VitalReading.class);
        when(reading.getId()).thenReturn(id);
        return reading;
    }

    @Test
    @DisplayName("leitura nova aciona PRC_REGISTRAR_ALERTAS_LEITURA e devolve o OUT")
    void generateAlertsCallsProcedure() throws SQLException {
        when(statement.getInt(2)).thenReturn(3);

        int created = routines.generateAlerts(readingWithId(42L));

        assertThat(created).isEqualTo(3);
        verify(jdbc).execute(eq("{call prc_registrar_alertas_leitura(?, ?)}"), any(CallableStatementCallback.class));
        verify(statement).setLong(1, 42L);
        verify(statement).registerOutParameter(2, Types.NUMERIC);
        verify(statement).execute();
    }

    @Test
    @DisplayName("consolidacao em lote envia paciente NULL para a procedure")
    void consolidateAllSendsNullPatient() throws SQLException {
        when(statement.getInt(3)).thenReturn(5);

        routines.consolidateAll(30);

        verify(jdbc).execute(eq("{call prc_consolidar_relatorio(?, ?, ?)}"), any(CallableStatementCallback.class));
        verify(statement).setNull(1, Types.NUMERIC);
        verify(statement).setInt(2, 30);
        verify(statement).registerOutParameter(3, Types.NUMERIC);
    }

    @Test
    @DisplayName("ORA-20001 da procedure chega ao servico como recurso inexistente")
    void translatesProcedureErrors() {
        when(jdbc.execute(anyString(), any(CallableStatementCallback.class)))
                .thenThrow(new UncategorizedSQLException("call", "{call prc_registrar_alertas_leitura(?, ?)}",
                        new SQLException("ORA-20001: Leitura 42 nao encontrada.", "72000", 20001)));

        assertThatThrownBy(() -> routines.generateAlerts(readingWithId(42L)))
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Leitura 42 nao encontrada.");
    }

    @Test
    void reportsEngine() {
        assertThat(routines.engine()).isEqualTo("ORACLE_PLSQL");
    }
}
