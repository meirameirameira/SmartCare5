-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 6
-- 00_drop.sql - remove os objetos do esquema para uma reinstalacao limpa.
-- Ignora objetos inexistentes (ORA-00942 / ORA-04043), entao pode ser
-- executado em um esquema vazio.
-- =============================================================================
DECLARE
    TYPE t_lista IS TABLE OF VARCHAR2(200);

    v_rotinas t_lista := t_lista(
        'PROCEDURE prc_consolidar_relatorio',
        'PROCEDURE prc_registrar_leitura',
        'PROCEDURE prc_registrar_alertas_leitura',
        'PROCEDURE prc_log_execucao',
        'FUNCTION fn_formatar_resumo_paciente',
        'FUNCTION fn_formatar_leitura',
        'FUNCTION fn_rotulo_nivel',
        'FUNCTION fn_tempo_na_faixa',
        'FUNCTION fn_calcular_score_saude',
        'FUNCTION fn_classificar_sinal');

    -- Ordem inversa das dependencias (filhas antes das maes).
    v_tabelas t_lista := t_lista(
        'routine_execution_log', 'patient_report', 'vital_reference_range',
        'delivery_order', 'health_alert', 'vital_reading', 'appointment',
        'doctor', 'app_user', 'patient_condition', 'patient');

    e_objeto_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_objeto_inexistente, -4043);
    e_tabela_inexistente EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_tabela_inexistente, -942);
BEGIN
    FOR i IN 1 .. v_rotinas.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP ' || v_rotinas(i);
        EXCEPTION
            WHEN e_objeto_inexistente THEN NULL;
        END;
    END LOOP;

    FOR i IN 1 .. v_tabelas.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ' || v_tabelas(i) || ' CASCADE CONSTRAINTS PURGE';
        EXCEPTION
            WHEN e_tabela_inexistente THEN NULL;
        END;
    END LOOP;
END;
/
