-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 04_pkg_monitoramento.sql - PKG_MONITORAMENTO: ingestao de leituras e alertas
--
--   PRC_REGISTRAR_ALERTAS_LEITURA  gera alertas a partir de uma leitura alterada
--                                  -> chamada pela API Java a cada leitura
--                                     recebida (REST -> Java -> JDBC -> Oracle)
--   PRC_REGISTRAR_LEITURA          ingestao direta do gateway IoT / carga
--   PRC_RECONHECER_ALERTA          equipe confirma que tratou o alerta
--
-- Controle transacional: as procedures de negocio NAO fazem COMMIT. Quem
-- decide e o chamador - o @Transactional da API ou o script/SQL Developer.
-- Assim a leitura e os alertas que ela gera sao gravados juntos, ou nada e.
-- Faixas de erro reservadas: -20001 a -20009.
-- =============================================================================

CREATE OR REPLACE PACKAGE pkg_monitoramento
IS
    -- -------------------------------------------------------------------------
    -- PRC_REGISTRAR_ALERTAS_LEITURA
    -- Proposito : avaliar cada metrica de uma leitura contra as faixas de
    --             referencia e abrir um alerta para cada sinal fora do normal:
    --               CRITICAL  -> alerta URGENT, com orientacao de acionar o SAMU
    --               ATTENTION -> alerta WARNING
    --             Um alerta ainda aberto para a mesma metrica nao e duplicado.
    --             Titulo, descricao e metrica seguem o mesmo texto do
    --             AlertService (Java): alertas do banco e da API sao
    --             indistinguiveis no app.
    -- Parametros: p_reading_id      IN  leitura recem-gravada
    --             p_alertas_criados OUT quantidade de alertas abertos
    -- Erros     : -20001 leitura inexistente
    -- Integracao: VitalService.record() -> PlsqlClinicalRoutines -> JDBC
    -- -------------------------------------------------------------------------
    PROCEDURE prc_registrar_alertas_leitura (
        p_reading_id      IN  NUMBER,
        p_alertas_criados OUT NUMBER
    );

    -- -------------------------------------------------------------------------
    -- PRC_REGISTRAR_LEITURA
    -- Proposito : porta de entrada do gateway IoT e das cargas em lote direto
    --             no banco. Valida o paciente e a data, grava a leitura e
    --             dispara PRC_REGISTRAR_ALERTAS_LEITURA na mesma transacao.
    -- Parametros: dados da leitura (IN), p_measured_at opcional (default: agora)
    --             p_reading_id OUT id gerado | p_alertas OUT alertas abertos
    -- Erros     : -20004 paciente inexistente | -20006 data no futuro
    --             -20007 valor fora do limite fisiologico (CHECK da tabela)
    -- -------------------------------------------------------------------------
    PROCEDURE prc_registrar_leitura (
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
    );

    -- -------------------------------------------------------------------------
    -- PRC_RECONHECER_ALERTA
    -- Proposito : marcar o alerta como tratado pela equipe. A data do
    --             reconhecimento e a linha de auditoria sao preenchidas pelas
    --             triggers de HEALTH_ALERT - aqui so muda o status.
    -- Erros     : -20002 alerta inexistente
    -- -------------------------------------------------------------------------
    PROCEDURE prc_reconhecer_alerta (p_alert_id IN NUMBER);
END pkg_monitoramento;
/

CREATE OR REPLACE PACKAGE BODY pkg_monitoramento
IS
    PROCEDURE prc_registrar_alertas_leitura (
        p_reading_id      IN  NUMBER,
        p_alertas_criados OUT NUMBER
    )
    IS
        c_rotina  CONSTANT VARCHAR2(60) := 'PKG_MONITORAMENTO.PRC_REGISTRAR_ALERTAS_LEITURA';
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
            v_status := pkg_clinico.fn_classificar_sinal(m.metric_code, m.valor);

            IF v_status IN (pkg_clinico.c_atencao, pkg_clinico.c_critico) THEN
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

                    IF v_status = pkg_clinico.c_critico THEN
                        v_descricao := 'Valor critico para a faixa de referencia (' || v_faixa_txt || ').'
                                    || ' Havendo sintomas, acione o 192 (SAMU).';
                    ELSE
                        v_descricao := 'Fora da faixa ideal (' || v_faixa_txt || '). Monitorar.';
                    END IF;

                    INSERT INTO health_alert (patient_id, type, title, description, metric, acknowledged, created_at)
                    VALUES (v_patient_id,
                            CASE v_status WHEN pkg_clinico.c_critico THEN 'URGENT' ELSE 'WARNING' END,
                            m.metric_name || ': ' || v_valor_txt || ' ' || m.unit,
                            v_descricao,
                            m.metric_name,
                            0,
                            SYSTIMESTAMP);

                    p_alertas_criados := p_alertas_criados + 1;
                END IF;
            END IF;
        END LOOP;

        pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_sucesso, p_alertas_criados,
            'Leitura ' || p_reading_id || ' do paciente ' || v_patient_id || ' avaliada.');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0, 'Leitura inexistente: ' || p_reading_id);
            RAISE_APPLICATION_ERROR(-20001, 'Leitura ' || p_reading_id || ' nao encontrada.');
        WHEN OTHERS THEN
            pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0, 'Leitura ' || p_reading_id || ': ' || SQLERRM);
            RAISE;
    END prc_registrar_alertas_leitura;

    PROCEDURE prc_registrar_leitura (
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
        c_rotina CONSTANT VARCHAR2(60) := 'PKG_MONITORAMENTO.PRC_REGISTRAR_LEITURA';

        -- ORA-02290: violacao de CHECK constraint (limites fisiologicos).
        e_fora_do_limite EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_fora_do_limite, -2290);

        v_existe  PLS_INTEGER;
        v_momento TIMESTAMP WITH TIME ZONE := NVL(p_measured_at, SYSTIMESTAMP);
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
            pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0, 'Paciente ' || p_patient_id || ': ' || SQLERRM);
            RAISE_APPLICATION_ERROR(-20007, 'Leitura fora do limite fisiologico aceito pelo sistema.');
    END prc_registrar_leitura;

    PROCEDURE prc_reconhecer_alerta (p_alert_id IN NUMBER)
    IS
        c_rotina CONSTANT VARCHAR2(60) := 'PKG_MONITORAMENTO.PRC_RECONHECER_ALERTA';
    BEGIN
        UPDATE health_alert
           SET acknowledged = 1
         WHERE id = p_alert_id;

        IF SQL%ROWCOUNT = 0 THEN
            pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0, 'Alerta inexistente: ' || p_alert_id);
            RAISE_APPLICATION_ERROR(-20002, 'Alerta ' || p_alert_id || ' nao encontrado.');
        END IF;

        pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_sucesso, 1, 'Alerta ' || p_alert_id || ' reconhecido.');
    END prc_reconhecer_alerta;
END pkg_monitoramento;
/
