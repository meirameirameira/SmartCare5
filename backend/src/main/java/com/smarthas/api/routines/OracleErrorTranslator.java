package com.smarthas.api.routines;

import com.smarthas.api.web.error.BusinessRuleException;
import com.smarthas.api.web.error.ResourceNotFoundException;
import java.sql.SQLException;
import org.springframework.dao.DataAccessException;

/**
 * Traduz os erros de negocio das rotinas PL/SQL para excecoes de dominio.
 *
 * <p>Os packages e triggers usam {@code RAISE_APPLICATION_ERROR} com codigos
 * reservados (ver {@code database/oracle/README.md}). Aqui cada faixa vira a
 * excecao que o {@code ApiExceptionHandler} ja sabe responder:</p>
 * <ul>
 *   <li>-20001 leitura, -20002 alerta e -20004 paciente inexistentes: 404;</li>
 *   <li>-20003 periodo invalido, -20005 falha de consolidacao, -20006 data
 *       futura, -20007 limite fisiologico, -20008 retencao de log, -20010 a
 *       -20016 parametros das functions e consultas dinamicas, -20020
 *       transicao de status barrada por trigger: 422.</li>
 * </ul>
 * <p>Qualquer outro erro do banco segue como esta e vira 500 com log.</p>
 */
public final class OracleErrorTranslator {

    private OracleErrorTranslator() {
    }

    public static RuntimeException translate(DataAccessException ex) {
        SQLException sql = findSqlException(ex);
        if (sql == null) {
            return ex;
        }

        String message = applicationMessage(sql);
        return switch (sql.getErrorCode()) {
            case 20001, 20002, 20004 -> new ResourceNotFoundException(message);
            case 20003, 20005, 20006, 20007, 20008, 20010, 20011, 20012, 20013, 20014, 20015, 20016, 20020 ->
                    new BusinessRuleException(message);
            default -> ex;
        };
    }

    private static SQLException findSqlException(Throwable error) {
        for (Throwable current = error; current != null; current = current.getCause()) {
            if (current instanceof SQLException sql) {
                return sql;
            }
        }
        return null;
    }

    /**
     * Extrai apenas o texto escrito na procedure.
     *
     * <p>O Oracle devolve algo como {@code "ORA-20004: Paciente 9 nao
     * encontrado.\nORA-06512: at ..."}; o cliente recebe so
     * {@code "Paciente 9 nao encontrado."}.</p>
     */
    static String applicationMessage(SQLException sql) {
        String raw = sql.getMessage() == null ? "" : sql.getMessage();
        String firstLine = raw.lines().findFirst().orElse("").trim();
        int separator = firstLine.indexOf(": ");
        return firstLine.startsWith("ORA-") && separator > 0
                ? firstLine.substring(separator + 2).trim()
                : firstLine;
    }
}
