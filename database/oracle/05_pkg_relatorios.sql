-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 05_pkg_relatorios.sql - PKG_RELATORIOS: consolidacao clinica e de consumo
--
--   PRC_CONSOLIDAR_RELATORIO  relatorio por paciente e periodo em PATIENT_REPORT
--                             -> chamada pela API Java no endpoint de
--                                relatorio do app e do painel
-- =============================================================================

CREATE OR REPLACE PACKAGE pkg_relatorios
IS
    -- -------------------------------------------------------------------------
    -- PRC_CONSOLIDAR_RELATORIO
    -- Proposito : gerar o relatorio clinico e de consumo de um paciente (ou de
    --             todos, quando p_patient_id e NULL) para o periodo informado e
    --             grava-lo em PATIENT_REPORT (MERGE: uma linha por paciente e
    --             periodo, sempre atualizada). Consolida:
    --               - quantidade de leituras e medias de cada sinal vital;
    --               - score atual e score medio do periodo;
    --               - tempo de glicemia na faixa;
    --               - alertas abertos, urgentes e emitidos no periodo;
    --               - consumo de medicamentos: pedidos feitos e entregues;
    --               - resumo textual.
    --             Uma falha em um paciente nao interrompe os demais: o trabalho
    --             daquele paciente volta ao SAVEPOINT e o erro vai para o log.
    -- Parametros: p_patient_id  IN  paciente, ou NULL para todos
    --             p_dias        IN  janela do relatorio (1 a 365, default 30)
    --             p_processados OUT pacientes consolidados com sucesso
    -- Erros     : -20003 periodo invalido | -20004 paciente inexistente
    --             -20005 falha ao consolidar o paciente solicitado
    -- Integracao: GET /api/v1/patients/{id}/report e
    --             POST /api/v1/reports/consolidation -> PlsqlClinicalRoutines
    -- -------------------------------------------------------------------------
    PROCEDURE prc_consolidar_relatorio (
        p_patient_id  IN  NUMBER DEFAULT NULL,
        p_dias        IN  NUMBER DEFAULT 30,
        p_processados OUT NUMBER
    );
END pkg_relatorios;
/

CREATE OR REPLACE PACKAGE BODY pkg_relatorios
IS
    PROCEDURE prc_consolidar_relatorio (
        p_patient_id  IN  NUMBER DEFAULT NULL,
        p_dias        IN  NUMBER DEFAULT 30,
        p_processados OUT NUMBER
    )
    IS
        c_rotina CONSTANT VARCHAR2(60) := 'PKG_RELATORIOS.PRC_CONSOLIDAR_RELATORIO';

        CURSOR c_pacientes IS
            SELECT id
              FROM patient
             WHERE p_patient_id IS NULL
                OR id = p_patient_id
             ORDER BY id;

        e_periodo_invalido     EXCEPTION;
        e_paciente_inexistente EXCEPTION;
        e_falha_paciente       EXCEPTION;

        v_desde         TIMESTAMP WITH TIME ZONE;
        v_leituras      PLS_INTEGER;
        v_media_fc      NUMBER;
        v_media_spo2    NUMBER;
        v_media_glic    NUMBER;
        v_media_sis     NUMBER;
        v_media_dia     NUMBER;
        v_media_temp    NUMBER;
        v_score_medio   NUMBER;
        v_ultima_id     vital_reading.id%TYPE;
        v_score_atual   NUMBER;
        v_tir_glicemia  NUMBER;
        v_abertos       PLS_INTEGER;
        v_urgentes      PLS_INTEGER;
        v_alertas_per   PLS_INTEGER;
        v_pedidos       PLS_INTEGER;
        v_entregues     PLS_INTEGER;
        v_resumo        patient_report.summary_text%TYPE;
        v_falhas        PLS_INTEGER := 0;
        v_ultimo_erro   VARCHAR2(4000);
    BEGIN
        p_processados := 0;

        IF p_dias IS NULL OR p_dias NOT BETWEEN 1 AND 365 THEN
            RAISE e_periodo_invalido;
        END IF;

        v_desde := SYSTIMESTAMP - NUMTODSINTERVAL(p_dias, 'DAY');

        FOR p IN c_pacientes LOOP
            BEGIN
                SAVEPOINT sp_paciente;

                -- Sinais vitais do periodo: medias e score medio em uma unica varredura.
                SELECT COUNT(*),
                       ROUND(AVG(heart_rate), 1),
                       ROUND(AVG(spo2), 1),
                       ROUND(AVG(glucose_level), 1),
                       ROUND(AVG(bp_systolic), 1),
                       ROUND(AVG(bp_diastolic), 1),
                       ROUND(AVG(temperature), 1),
                       ROUND(AVG(pkg_clinico.fn_calcular_score_saude(id)), 1)
                  INTO v_leituras, v_media_fc, v_media_spo2, v_media_glic,
                       v_media_sis, v_media_dia, v_media_temp, v_score_medio
                  FROM vital_reading
                 WHERE patient_id  = p.id
                   AND measured_at >= v_desde;

                -- Score atual: sempre a leitura mais recente, mesmo fora da janela.
                SELECT MAX(id) KEEP (DENSE_RANK LAST ORDER BY measured_at)
                  INTO v_ultima_id
                  FROM vital_reading
                 WHERE patient_id = p.id;

                v_score_atual  := pkg_clinico.fn_calcular_score_saude(v_ultima_id);
                v_tir_glicemia := pkg_clinico.fn_tempo_na_faixa(p.id, 'GLUCOSE', p_dias);

                SELECT COUNT(CASE WHEN acknowledged = 0 THEN 1 END),
                       COUNT(CASE WHEN acknowledged = 0 AND type = 'URGENT' THEN 1 END),
                       COUNT(CASE WHEN created_at >= v_desde THEN 1 END)
                  INTO v_abertos, v_urgentes, v_alertas_per
                  FROM health_alert
                 WHERE patient_id = p.id;

                -- Consumo de medicamentos no periodo (camada AI Logistics).
                SELECT COUNT(CASE WHEN status <> 'CANCELLED' THEN 1 END),
                       COUNT(CASE WHEN status = 'DELIVERED' THEN 1 END)
                  INTO v_pedidos, v_entregues
                  FROM delivery_order
                 WHERE patient_id = p.id
                   AND created_at >= v_desde;

                v_resumo := pkg_clinico.fn_formatar_resumo_paciente(p.id, p_dias);

                MERGE INTO patient_report t
                USING (SELECT p.id AS patient_id, p_dias AS period_days FROM dual) s
                   ON (t.patient_id = s.patient_id AND t.period_days = s.period_days)
                WHEN MATCHED THEN UPDATE SET
                    t.generated_at          = SYSTIMESTAMP,
                    t.readings_count        = v_leituras,
                    t.avg_heart_rate        = v_media_fc,
                    t.avg_spo2              = v_media_spo2,
                    t.avg_glucose           = v_media_glic,
                    t.avg_systolic          = v_media_sis,
                    t.avg_diastolic         = v_media_dia,
                    t.avg_temperature       = v_media_temp,
                    t.latest_score          = v_score_atual,
                    t.average_score         = v_score_medio,
                    t.risk_level            = pkg_clinico.fn_rotulo_nivel(v_score_atual),
                    t.glucose_time_in_range = v_tir_glicemia,
                    t.open_alerts           = v_abertos,
                    t.urgent_alerts         = v_urgentes,
                    t.alerts_in_period      = v_alertas_per,
                    t.deliveries_total      = v_pedidos,
                    t.deliveries_delivered  = v_entregues,
                    t.summary_text          = v_resumo
                WHEN NOT MATCHED THEN INSERT (
                    patient_id, period_days, generated_at, readings_count,
                    avg_heart_rate, avg_spo2, avg_glucose, avg_systolic, avg_diastolic, avg_temperature,
                    latest_score, average_score, risk_level, glucose_time_in_range,
                    open_alerts, urgent_alerts, alerts_in_period,
                    deliveries_total, deliveries_delivered, summary_text)
                VALUES (
                    s.patient_id, s.period_days, SYSTIMESTAMP, v_leituras,
                    v_media_fc, v_media_spo2, v_media_glic, v_media_sis, v_media_dia, v_media_temp,
                    v_score_atual, v_score_medio, pkg_clinico.fn_rotulo_nivel(v_score_atual), v_tir_glicemia,
                    v_abertos, v_urgentes, v_alertas_per,
                    v_pedidos, v_entregues, v_resumo);

                p_processados := p_processados + 1;
            EXCEPTION
                WHEN OTHERS THEN
                    ROLLBACK TO sp_paciente;
                    v_falhas      := v_falhas + 1;
                    v_ultimo_erro := 'Paciente ' || p.id || ': ' || SQLERRM;
                    pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0, v_ultimo_erro);
            END;
        END LOOP;

        IF p_patient_id IS NOT NULL THEN
            IF v_falhas > 0 THEN
                RAISE e_falha_paciente;
            ELSIF p_processados = 0 THEN
                RAISE e_paciente_inexistente;
            END IF;
        END IF;

        pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_sucesso, p_processados,
            p_processados || ' paciente(s) consolidado(s), ' || v_falhas
            || ' falha(s), janela de ' || p_dias || ' dias.');
    EXCEPTION
        WHEN e_periodo_invalido THEN
            pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0,
                'Periodo invalido: ' || NVL(TO_CHAR(p_dias), 'nulo'));
            RAISE_APPLICATION_ERROR(-20003, 'Periodo invalido: informe entre 1 e 365 dias.');
        WHEN e_paciente_inexistente THEN
            pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0, 'Paciente inexistente: ' || p_patient_id);
            RAISE_APPLICATION_ERROR(-20004, 'Paciente ' || p_patient_id || ' nao encontrado.');
        WHEN e_falha_paciente THEN
            RAISE_APPLICATION_ERROR(-20005, 'Nao foi possivel consolidar o relatorio. ' || v_ultimo_erro);
    END prc_consolidar_relatorio;
END pkg_relatorios;
/
