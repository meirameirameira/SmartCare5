-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 02_pkg_auditoria.sql - PKG_AUDITORIA: governanca das rotinas do banco
--
--   PRC_LOG_EXECUCAO      trilha de auditoria (transacao autonoma)
--   PRC_EXPURGAR_LOGS     politica de retencao da trilha
--
-- E o primeiro package instalado: todos os outros registram nele o sucesso ou
-- a falha de cada execucao.
-- =============================================================================

CREATE OR REPLACE PACKAGE pkg_auditoria
IS
    c_sucesso CONSTANT VARCHAR2(10) := 'SUCCESS';
    c_erro    CONSTANT VARCHAR2(10) := 'ERROR';

    -- -------------------------------------------------------------------------
    -- PRC_LOG_EXECUCAO
    -- Proposito : registrar sucesso ou falha de qualquer rotina em
    --             ROUTINE_EXECUTION_LOG. Usa PRAGMA AUTONOMOUS_TRANSACTION: o
    --             log e confirmado mesmo quando a transacao principal sofre
    --             ROLLBACK, e nunca interfere no COMMIT do chamador.
    -- Parametros: p_rotina, p_status (c_sucesso | c_erro), p_linhas, p_mensagem
    -- -------------------------------------------------------------------------
    PROCEDURE prc_log_execucao (
        p_rotina   IN VARCHAR2,
        p_status   IN VARCHAR2,
        p_linhas   IN NUMBER   DEFAULT 0,
        p_mensagem IN VARCHAR2 DEFAULT NULL
    );

    -- -------------------------------------------------------------------------
    -- PRC_EXPURGAR_LOGS
    -- Proposito : aplicar a politica de retencao - apaga registros de log e de
    --             auditoria de alertas mais antigos que p_dias_retencao.
    -- Parametros: p_dias_retencao IN  minimo de 30 dias (LGPD: a trilha de
    --                                 dados de saude nao some por engano)
    --             p_removidos     OUT linhas apagadas nas duas tabelas
    -- Erros     : -20008 retencao menor que 30 dias
    -- -------------------------------------------------------------------------
    PROCEDURE prc_expurgar_logs (
        p_dias_retencao IN  NUMBER DEFAULT 180,
        p_removidos     OUT NUMBER
    );
END pkg_auditoria;
/

CREATE OR REPLACE PACKAGE BODY pkg_auditoria
IS
    PROCEDURE prc_log_execucao (
        p_rotina   IN VARCHAR2,
        p_status   IN VARCHAR2,
        p_linhas   IN NUMBER   DEFAULT 0,
        p_mensagem IN VARCHAR2 DEFAULT NULL
    )
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        INSERT INTO routine_execution_log (routine_name, status, rows_affected, message)
        VALUES (UPPER(SUBSTR(p_rotina, 1, 60)), p_status, NVL(p_linhas, 0), SUBSTR(p_mensagem, 1, 4000));
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            -- Auditoria nunca pode derrubar a operacao de negocio.
            ROLLBACK;
    END prc_log_execucao;

    PROCEDURE prc_expurgar_logs (
        p_dias_retencao IN  NUMBER DEFAULT 180,
        p_removidos     OUT NUMBER
    )
    IS
        c_rotina CONSTANT VARCHAR2(60) := 'PKG_AUDITORIA.PRC_EXPURGAR_LOGS';
        v_limite TIMESTAMP WITH TIME ZONE;
    BEGIN
        IF p_dias_retencao IS NULL OR p_dias_retencao < 30 THEN
            RAISE_APPLICATION_ERROR(-20008, 'Retencao minima da trilha de auditoria: 30 dias.');
        END IF;

        v_limite := SYSTIMESTAMP - NUMTODSINTERVAL(p_dias_retencao, 'DAY');

        DELETE FROM routine_execution_log WHERE executed_at < v_limite;
        p_removidos := SQL%ROWCOUNT;

        DELETE FROM health_alert_audit WHERE changed_at < v_limite;
        p_removidos := p_removidos + SQL%ROWCOUNT;

        prc_log_execucao(c_rotina, c_sucesso, p_removidos,
                         'Retencao de ' || p_dias_retencao || ' dias aplicada.');
    END prc_expurgar_logs;
END pkg_auditoria;
/
