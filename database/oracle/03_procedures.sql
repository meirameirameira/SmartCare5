-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 6
-- 03_procedures.sql - procedures PL/SQL (rotinas automatizadas no banco)
--
--   PRC_LOG_EXECUCAO               trilha de auditoria (transacao autonoma)
--   PRC_REGISTRAR_ALERTAS_LEITURA  gera alertas a partir de uma leitura critica
--                                  -> chamada pela API Java a cada leitura
--                                     recebida (REST -> Java -> JDBC -> Oracle)
--   PRC_REGISTRAR_LEITURA          ingestao direta do gateway IoT / carga
--   PRC_CONSOLIDAR_RELATORIO       relatorio clinico e de consumo por paciente
--                                  -> chamada pela API Java no endpoint de
--                                     relatorio do app e do painel
--
-- Controle transacional: as procedures de negocio NAO fazem COMMIT. Quem
-- decide e o chamador - o @Transactional da API ou o script/SQL Developer.
-- Assim a leitura e os alertas que ela gera sao gravados juntos, ou nada e.
-- Faixas de erro reservadas: -20001 a -20009.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- PRC_LOG_EXECUCAO
-- Proposito : registrar sucesso ou falha de qualquer rotina em
--             ROUTINE_EXECUTION_LOG. Usa PRAGMA AUTONOMOUS_TRANSACTION: o log
--             e confirmado mesmo quando a transacao principal sofre ROLLBACK,
--             e nunca interfere no COMMIT do chamador.
-- Parametros: p_rotina, p_status ('SUCCESS'|'ERROR'), p_linhas, p_mensagem
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_log_execucao (
    p_rotina   IN VARCHAR2,
    p_status   IN VARCHAR2,
    p_linhas   IN NUMBER   DEFAULT 0,
    p_mensagem IN VARCHAR2 DEFAULT NULL
)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO routine_execution_log (routine_name, status, rows_affected, message)
    VALUES (UPPER(p_rotina), p_status, NVL(p_linhas, 0), SUBSTR(p_mensagem, 1, 4000));
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        -- Auditoria nunca pode derrubar a operacao de negocio.
        ROLLBACK;
END prc_log_execucao;
/

-- -----------------------------------------------------------------------------
-- PRC_REGISTRAR_ALERTAS_LEITURA
-- Proposito : avaliar cada metrica de uma leitura contra as faixas de
--             referencia e abrir um alerta para cada sinal fora do normal:
--               CRITICAL  -> alerta URGENT, com orientacao de acionar o SAMU
--               ATTENTION -> alerta WARNING
--             Um alerta ainda aberto para a mesma metrica nao e duplicado: o
--             paciente nao recebe a mesma notificacao a cada leitura enquanto
--             a alteracao persistir. Titulo, descricao e metrica seguem o
--             mesmo texto do AlertService (Java), para que os alertas gerados
--             no banco e na API sejam indistinguiveis no app.
-- Parametros: p_reading_id      IN  leitura recem-gravada
--             p_alertas_criados OUT quantidade de alertas abertos
-- Erros     : -20001 leitura inexistente
-- Integracao: VitalService.record() -> PlsqlClinicalRoutines -> JDBC
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_registrar_alertas_leitura (
    p_reading_id      IN  NUMBER,
    p_alertas_criados OUT NUMBER
)
IS
    c_rotina  CONSTANT VARCHAR2(60) := 'PRC_REGISTRAR_ALERTAS_LEITURA';
    c_decimal CONSTANT VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS=''.,''';

    CURSOR c_metricas (pc_reading_id NUMBER) IS
        SELECT r.metric_code,
               r.metric_name,
               r.unit,
               r.normal_min,
               r.normal_max,
               CASE r.metric_code
                   WHEN 'HEART_RATE'  THEN v.heart_rate
                   WHEN 'SPO2'        THEN v.spo2
                   WHEN 'GLUCOSE'     THEN v.glucose_level
                   WHEN 'SYSTOLIC'    THEN v.bp_systolic
                   WHEN 'DIASTOLIC'   THEN v.bp_diastolic
                   WHEN 'TEMPERATURE' THEN v.temperature
               END AS valor
          FROM vital_reading v
         CROSS JOIN vital_reference_range r
         WHERE v.id = pc_reading_id
         ORDER BY r.display_order;

    v_patient_id vital_reading.patient_id%TYPE;
    v_status     VARCHAR2(10);
    v_abertos    PLS_INTEGER;
    v_valor_txt  VARCHAR2(20);
    v_faixa_txt  VARCHAR2(60);
    v_descricao  health_alert.description%TYPE;
BEGIN
    p_alertas_criados := 0;

    -- Garante que a leitura existe (NO_DATA_FOUND tratado abaixo).
    SELECT patient_id
      INTO v_patient_id
      FROM vital_reading
     WHERE id = p_reading_id;

    FOR m IN c_metricas(p_reading_id) LOOP
        v_status := fn_classificar_sinal(m.metric_code, m.valor);

        IF v_status IN ('ATTENTION', 'CRITICAL') THEN
            SELECT COUNT(*)
              INTO v_abertos
              FROM health_alert
             WHERE patient_id   = v_patient_id
               AND metric       = m.metric_name
               AND acknowledged = 0;

            IF v_abertos = 0 THEN
                -- Mesmo formato numerico da API: ponto decimal, 1 casa para
                -- SpO2 e temperatura.
                IF m.metric_code IN ('SPO2', 'TEMPERATURE') THEN
                    v_valor_txt := TO_CHAR(m.valor, 'FM990D0', c_decimal);
                ELSE
                    v_valor_txt := TO_CHAR(m.valor, 'TM9', c_decimal);
                END IF;

                v_faixa_txt := TO_CHAR(m.normal_min, 'TM9', c_decimal) || '-'
                            || TO_CHAR(m.normal_max, 'TM9', c_decimal) || ' ' || m.unit;

                IF v_status = 'CRITICAL' THEN
                    v_descricao := 'Valor critico para a faixa de referencia (' || v_faixa_txt || ').'
                                || ' Havendo sintomas, acione o 192 (SAMU).';
                ELSE
                    v_descricao := 'Fora da faixa ideal (' || v_faixa_txt || '). Monitorar.';
                END IF;

                INSERT INTO health_alert (patient_id, type, title, description, metric, acknowledged, created_at)
                VALUES (v_patient_id,
                        CASE v_status WHEN 'CRITICAL' THEN 'URGENT' ELSE 'WARNING' END,
                        m.metric_name || ': ' || v_valor_txt || ' ' || m.unit,
                        v_descricao,
                        m.metric_name,
                        0,
                        SYSTIMESTAMP);

                p_alertas_criados := p_alertas_criados + 1;
            END IF;
        END IF;
    END LOOP;

    prc_log_execucao(c_rotina, 'SUCCESS', p_alertas_criados,
                     'Leitura ' || p_reading_id || ' do paciente ' || v_patient_id || ' avaliada.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        prc_log_execucao(c_rotina, 'ERROR', 0, 'Leitura inexistente: ' || p_reading_id);
        RAISE_APPLICATION_ERROR(-20001, 'Leitura ' || p_reading_id || ' nao encontrada.');
    WHEN OTHERS THEN
        prc_log_execucao(c_rotina, 'ERROR', 0, 'Leitura ' || p_reading_id || ': ' || SQLERRM);
        RAISE;
END prc_registrar_alertas_leitura;
/

-- -----------------------------------------------------------------------------
-- PRC_REGISTRAR_LEITURA
-- Proposito : porta de entrada do gateway IoT e das cargas em lote direto no
--             banco. Valida o paciente e a data, grava a leitura e dispara
--             PRC_REGISTRAR_ALERTAS_LEITURA na mesma transacao.
-- Parametros: dados da leitura (IN), p_measured_at opcional (default: agora)
--             p_reading_id OUT id gerado | p_alertas OUT alertas abertos
-- Erros     : -20004 paciente inexistente | -20006 data no futuro
--             -20007 valor fora do limite fisiologico (CHECK da tabela)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_registrar_leitura (
    p_patient_id  IN  NUMBER,
    p_heart_rate  IN  NUMBER,
    p_spo2        IN  NUMBER,
    p_glucose     IN  NUMBER,
    p_systolic    IN  NUMBER,
    p_diastolic   IN  NUMBER,
    p_temperature IN  NUMBER,
    p_measured_at IN  TIMESTAMP WITH TIME ZONE DEFAULT NULL,
    p_reading_id  OUT NUMBER,
    p_alertas     OUT NUMBER
)
IS
    c_rotina CONSTANT VARCHAR2(60) := 'PRC_REGISTRAR_LEITURA';

    -- ORA-02290: violacao de CHECK constraint (limites fisiologicos).
    e_fora_do_limite EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_fora_do_limite, -2290);

    v_existe    PLS_INTEGER;
    v_momento   TIMESTAMP WITH TIME ZONE := NVL(p_measured_at, SYSTIMESTAMP);
BEGIN
    SELECT COUNT(*) INTO v_existe FROM patient WHERE id = p_patient_id;
    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Paciente ' || p_patient_id || ' nao encontrado.');
    END IF;

    -- Mesma tolerancia da API: ate 5 minutos de diferenca de relogio.
    IF v_momento > SYSTIMESTAMP + NUMTODSINTERVAL(5, 'MINUTE') THEN
        RAISE_APPLICATION_ERROR(-20006, 'A data da medicao nao pode estar no futuro.');
    END IF;

    INSERT INTO vital_reading (patient_id, heart_rate, spo2, glucose_level,
                               bp_systolic, bp_diastolic, temperature, measured_at)
    VALUES (p_patient_id, p_heart_rate, p_spo2, p_glucose,
            p_systolic, p_diastolic, p_temperature, v_momento)
    RETURNING id INTO p_reading_id;

    prc_registrar_alertas_leitura(p_reading_id, p_alertas);
EXCEPTION
    WHEN e_fora_do_limite THEN
        prc_log_execucao(c_rotina, 'ERROR', 0, 'Paciente ' || p_patient_id || ': ' || SQLERRM);
        RAISE_APPLICATION_ERROR(-20007, 'Leitura fora do limite fisiologico aceito pelo sistema.');
END prc_registrar_leitura;
/

-- -----------------------------------------------------------------------------
-- PRC_CONSOLIDAR_RELATORIO
-- Proposito : gerar o relatorio clinico e de consumo de um paciente (ou de
--             todos, quando p_patient_id e NULL) para o periodo informado e
--             grava-lo em PATIENT_REPORT (MERGE: uma linha por paciente e
--             periodo, sempre atualizada). Consolida:
--               - quantidade de leituras e medias de cada sinal vital;
--               - score atual e score medio do periodo (FN_CALCULAR_SCORE_SAUDE);
--               - tempo de glicemia na faixa (FN_TEMPO_NA_FAIXA);
--               - alertas abertos, urgentes e emitidos no periodo;
--               - consumo de medicamentos: pedidos feitos e entregues;
--               - resumo textual (FN_FORMATAR_RESUMO_PACIENTE).
--             Uma falha em um paciente nao interrompe os demais: o trabalho
--             daquele paciente volta ao SAVEPOINT e o erro vai para o log.
-- Parametros: p_patient_id  IN  paciente, ou NULL para todos
--             p_dias        IN  janela do relatorio (1 a 365, default 30)
--             p_processados OUT pacientes consolidados com sucesso
-- Erros     : -20003 periodo invalido | -20004 paciente inexistente
--             -20005 falha ao consolidar o paciente solicitado
-- Integracao: GET /api/v1/patients/{id}/report e
--             POST /api/v1/reports/consolidation -> PlsqlClinicalRoutines
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE prc_consolidar_relatorio (
    p_patient_id  IN  NUMBER DEFAULT NULL,
    p_dias        IN  NUMBER DEFAULT 30,
    p_processados OUT NUMBER
)
IS
    c_rotina CONSTANT VARCHAR2(60) := 'PRC_CONSOLIDAR_RELATORIO';

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
                   ROUND(AVG(fn_calcular_score_saude(id)), 1)
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

            v_score_atual  := fn_calcular_score_saude(v_ultima_id);
            v_tir_glicemia := fn_tempo_na_faixa(p.id, 'GLUCOSE', p_dias);

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

            v_resumo := fn_formatar_resumo_paciente(p.id, p_dias);

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
                t.risk_level            = fn_rotulo_nivel(v_score_atual),
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
                v_score_atual, v_score_medio, fn_rotulo_nivel(v_score_atual), v_tir_glicemia,
                v_abertos, v_urgentes, v_alertas_per,
                v_pedidos, v_entregues, v_resumo);

            p_processados := p_processados + 1;
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK TO sp_paciente;
                v_falhas      := v_falhas + 1;
                v_ultimo_erro := 'Paciente ' || p.id || ': ' || SQLERRM;
                prc_log_execucao(c_rotina, 'ERROR', 0, v_ultimo_erro);
        END;
    END LOOP;

    IF p_patient_id IS NOT NULL THEN
        IF v_falhas > 0 THEN
            RAISE e_falha_paciente;
        ELSIF p_processados = 0 THEN
            RAISE e_paciente_inexistente;
        END IF;
    END IF;

    prc_log_execucao(c_rotina, 'SUCCESS', p_processados,
                     p_processados || ' paciente(s) consolidado(s), ' || v_falhas
                     || ' falha(s), janela de ' || p_dias || ' dias.');
EXCEPTION
    WHEN e_periodo_invalido THEN
        prc_log_execucao(c_rotina, 'ERROR', 0, 'Periodo invalido: ' || NVL(TO_CHAR(p_dias), 'nulo'));
        RAISE_APPLICATION_ERROR(-20003, 'Periodo invalido: informe entre 1 e 365 dias.');
    WHEN e_paciente_inexistente THEN
        prc_log_execucao(c_rotina, 'ERROR', 0, 'Paciente inexistente: ' || p_patient_id);
        RAISE_APPLICATION_ERROR(-20004, 'Paciente ' || p_patient_id || ' nao encontrado.');
    WHEN e_falha_paciente THEN
        RAISE_APPLICATION_ERROR(-20005, 'Nao foi possivel consolidar o relatorio. ' || v_ultimo_erro);
END prc_consolidar_relatorio;
/
