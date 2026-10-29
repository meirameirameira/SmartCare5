package com.smarthas.api.routines;

import static org.assertj.core.api.Assertions.assertThat;

import com.smarthas.api.web.error.BusinessRuleException;
import com.smarthas.api.web.error.ResourceNotFoundException;
import java.sql.SQLException;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.UncategorizedSQLException;

@DisplayName("Traducao dos erros RAISE_APPLICATION_ERROR")
class OracleErrorTranslatorTest {

    private static UncategorizedSQLException oracleError(int code, String message) {
        SQLException sql = new SQLException(
                "ORA-" + code + ": " + message + "\nORA-06512: at \"SMARTHAS.PRC_CONSOLIDAR_RELATORIO\", line 190\n",
                "72000", code);
        return new UncategorizedSQLException("CallableStatementCallback", "{call ...}", sql);
    }

    @Test
    @DisplayName("paciente, leitura ou alerta inexistente viram 404 com a mensagem da procedure")
    void notFound() {
        RuntimeException translated = OracleErrorTranslator.translate(oracleError(20004, "Paciente 9 nao encontrado."));

        assertThat(translated)
                .isInstanceOf(ResourceNotFoundException.class)
                .hasMessage("Paciente 9 nao encontrado.");
        assertThat(OracleErrorTranslator.translate(oracleError(20001, "Leitura 3 nao encontrada.")))
                .isInstanceOf(ResourceNotFoundException.class);
        assertThat(OracleErrorTranslator.translate(oracleError(20002, "Alerta 5 nao encontrado.")))
                .isInstanceOf(ResourceNotFoundException.class);
    }

    @Test
    @DisplayName("violacoes de regra viram 422")
    void businessRules() {
        for (int code : new int[] {20003, 20005, 20006, 20007, 20008, 20010, 20011, 20012,
                20013, 20014, 20015, 20016, 20020}) {
            assertThat(OracleErrorTranslator.translate(oracleError(code, "regra")))
                    .isInstanceOf(BusinessRuleException.class)
                    .hasMessage("regra");
        }
    }

    @Test
    @DisplayName("erros de infraestrutura nao sao mascarados")
    void otherErrorsPropagate() {
        UncategorizedSQLException original = oracleError(942, "table or view does not exist");

        assertThat(OracleErrorTranslator.translate(original)).isSameAs(original);
    }
}
