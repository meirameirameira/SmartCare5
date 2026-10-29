-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 6
-- 05_consultas_demonstracao.sql - uso pratico das functions e procedures
--
-- Rode bloco a bloco no SQL Developer (Ctrl+Enter) ou o arquivo inteiro (F5).
-- Os blocos que alteram dados terminam em ROLLBACK para manter a base de
-- demonstracao intacta - apenas o log de execucao (transacao autonoma) fica.
-- =============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 320
SET PAGESIZE 100
COLUMN paciente      FORMAT A16
COLUMN nivel         FORMAT A10
COLUMN resumo        FORMAT A300
COLUMN leitura       FORMAT A110
COLUMN glicemia      FORMAT A10
COLUMN spo2          FORMAT A10
COLUMN dia           FORMAT A6
COLUMN routine_name  FORMAT A30
COLUMN status        FORMAT A8
COLUMN quando        FORMAT A15
COLUMN mensagem      FORMAT A90

-- -----------------------------------------------------------------------------
-- Q1. Painel de risco: score atual de cada paciente, calculado no banco.
--     FN_CALCULAR_SCORE_SAUDE (indicador) + FN_ROTULO_NIVEL dentro do SELECT.
-- -----------------------------------------------------------------------------
SELECT p.id,
       p.name                                         AS paciente,
       p.age                                          AS idade,
       fn_calcular_score_saude(u.ultima_id)           AS score,
       fn_rotulo_nivel(fn_calcular_score_saude(u.ultima_id)) AS nivel
  FROM patient p
  LEFT JOIN (SELECT patient_id,
                    MAX(id) KEEP (DENSE_RANK LAST ORDER BY measured_at) AS ultima_id
               FROM vital_reading
              GROUP BY patient_id) u
    ON u.patient_id = p.id
 ORDER BY score NULLS LAST;

-- -----------------------------------------------------------------------------
-- Q2. Resumo clinico formatado de cada paciente (dado formatado).
-- -----------------------------------------------------------------------------
SELECT fn_formatar_resumo_paciente(id, 30) AS resumo
  FROM patient
 ORDER BY id;

-- -----------------------------------------------------------------------------
-- Q3. Tempo na faixa (Time in Range) por metrica nos ultimos 30 dias.
-- -----------------------------------------------------------------------------
SELECT name                                       AS paciente,
       fn_tempo_na_faixa(id, 'GLUCOSE', 30)       AS glicemia_pct,
       fn_tempo_na_faixa(id, 'SPO2', 30)          AS spo2_pct,
       fn_tempo_na_faixa(id, 'SYSTOLIC', 30)      AS sistolica_pct,
       fn_tempo_na_faixa(id, 'HEART_RATE', 30)    AS freq_cardiaca_pct
  FROM patient
 ORDER BY glicemia_pct NULLS LAST;

-- -----------------------------------------------------------------------------
-- Q4. Ultimas leituras de um paciente, formatadas e com score e classificacao
--     de cada sinal - a function e aplicada linha a linha.
-- -----------------------------------------------------------------------------
SELECT fn_formatar_leitura(v.id)                          AS leitura,
       fn_calcular_score_saude(v.id)                      AS score,
       fn_classificar_sinal('GLUCOSE', v.glucose_level)   AS glicemia,
       fn_classificar_sinal('SPO2', v.spo2)               AS spo2
  FROM vital_reading v
  JOIN patient p ON p.id = v.patient_id
 WHERE p.name = 'Joao Silva'
 ORDER BY v.measured_at DESC
 FETCH FIRST 6 ROWS ONLY;

-- -----------------------------------------------------------------------------
-- Q5. Evolucao diaria do score medio (ultimos 7 dias) - tendencia por paciente.
-- -----------------------------------------------------------------------------
SELECT p.name                                              AS paciente,
       TO_CHAR(TRUNC(CAST(v.measured_at AS DATE)), 'DD/MM') AS dia,
       COUNT(*)                                            AS leituras,
       ROUND(AVG(fn_calcular_score_saude(v.id)), 1)        AS score_medio
  FROM vital_reading v
  JOIN patient p ON p.id = v.patient_id
 WHERE v.measured_at >= SYSTIMESTAMP - INTERVAL '7' DAY
 GROUP BY p.name, TRUNC(CAST(v.measured_at AS DATE))
 ORDER BY p.name, TRUNC(CAST(v.measured_at AS DATE));

-- -----------------------------------------------------------------------------
-- Q6. Leituras em que o score caiu abaixo de 60 - candidatas a revisao clinica.
-- -----------------------------------------------------------------------------
SELECT p.name AS paciente, fn_formatar_leitura(v.id) AS leitura, fn_calcular_score_saude(v.id) AS score
  FROM vital_reading v
  JOIN patient p ON p.id = v.patient_id
 WHERE fn_calcular_score_saude(v.id) < 60
 ORDER BY v.measured_at DESC
 FETCH FIRST 15 ROWS ONLY;

-- -----------------------------------------------------------------------------
-- Q7. Relatorio consolidado (snapshot gravado pela PRC_CONSOLIDAR_RELATORIO).
-- -----------------------------------------------------------------------------
SELECT p.name AS paciente, r.period_days AS dias, r.readings_count AS leituras,
       r.latest_score AS score, r.average_score AS score_medio, r.risk_level AS nivel,
       r.glucose_time_in_range AS tir_glicemia, r.open_alerts AS alertas_abertos,
       r.urgent_alerts AS urgentes, r.deliveries_total AS pedidos, r.deliveries_delivered AS entregues
  FROM patient_report r
  JOIN patient p ON p.id = r.patient_id
 WHERE r.period_days = 30
 ORDER BY r.latest_score NULLS LAST;

-- -----------------------------------------------------------------------------
-- P1. PRC_REGISTRAR_LEITURA + PRC_REGISTRAR_ALERTAS_LEITURA
--     Simula o gateway IoT enviando uma leitura critica de Felipe.
--     Repetir o bloco nao duplica alertas: os alertas ja abertos sao reaproveitados.
-- -----------------------------------------------------------------------------
DECLARE
    v_paciente patient.id%TYPE;
    v_leitura  NUMBER;
    v_alertas  NUMBER;
BEGIN
    SELECT id INTO v_paciente FROM patient WHERE name = 'Felipe Meira';

    prc_registrar_leitura(
        p_patient_id  => v_paciente,
        p_heart_rate  => 121,
        p_spo2        => 91.2,
        p_glucose     => 215,
        p_systolic    => 141,
        p_diastolic   => 92,
        p_temperature => 38.1,
        p_reading_id  => v_leitura,
        p_alertas     => v_alertas);

    DBMS_OUTPUT.PUT_LINE('Leitura ' || v_leitura || ' gravada | score ' ||
                         fn_calcular_score_saude(v_leitura) || ' | ' || v_alertas || ' alerta(s) aberto(s)');
    DBMS_OUTPUT.PUT_LINE(fn_formatar_leitura(v_leitura));

    FOR a IN (SELECT type, title, description
                FROM health_alert
               WHERE patient_id = v_paciente AND acknowledged = 0
               ORDER BY id DESC
               FETCH FIRST 6 ROWS ONLY) LOOP
        DBMS_OUTPUT.PUT_LINE('  [' || RPAD(a.type, 7) || '] ' || a.title || ' - ' || a.description);
    END LOOP;

    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- P2. PRC_CONSOLIDAR_RELATORIO para um paciente, lendo o resultado em seguida.
-- -----------------------------------------------------------------------------
DECLARE
    v_paciente    patient.id%TYPE;
    v_processados NUMBER;
    v_rel         patient_report%ROWTYPE;
BEGIN
    SELECT id INTO v_paciente FROM patient WHERE name = 'Joao Silva';

    prc_consolidar_relatorio(v_paciente, 14, v_processados);

    SELECT * INTO v_rel
      FROM patient_report
     WHERE patient_id = v_paciente AND period_days = 14;

    DBMS_OUTPUT.PUT_LINE('Relatorio de 14 dias - ' || v_rel.readings_count || ' leituras');
    DBMS_OUTPUT.PUT_LINE('  Score atual/medio : ' || v_rel.latest_score || ' / ' || v_rel.average_score
                         || ' (' || v_rel.risk_level || ')');
    DBMS_OUTPUT.PUT_LINE('  Glicemia na faixa : ' || v_rel.glucose_time_in_range || '%');
    DBMS_OUTPUT.PUT_LINE('  Alertas           : ' || v_rel.open_alerts || ' abertos, '
                         || v_rel.urgent_alerts || ' urgentes');
    DBMS_OUTPUT.PUT_LINE('  Medicamentos      : ' || v_rel.deliveries_total || ' pedidos, '
                         || v_rel.deliveries_delivered || ' entregues');
    DBMS_OUTPUT.PUT_LINE('  ' || v_rel.summary_text);

    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- P3. Tratamento de excecoes: cada erro de negocio tem codigo proprio, que a
--     API Java traduz para o status HTTP correto (404, 422...).
-- -----------------------------------------------------------------------------
DECLARE
    v_n NUMBER;
    v_r NUMBER;

    PROCEDURE tentar (p_titulo VARCHAR2, p_bloco PLS_INTEGER) IS
    BEGIN
        CASE p_bloco
            WHEN 1 THEN prc_consolidar_relatorio(NULL, 0, v_n);              -- periodo invalido
            WHEN 2 THEN prc_consolidar_relatorio(-1, 30, v_n);               -- paciente inexistente
            WHEN 3 THEN prc_registrar_alertas_leitura(-1, v_n);              -- leitura inexistente
            WHEN 4 THEN prc_registrar_leitura(-1, 80, 97, 100, 120, 80, 36.5, NULL, v_r, v_n);
            WHEN 5 THEN v_n := fn_tempo_na_faixa(1, 'COLESTEROL', 30);       -- metrica desconhecida
        END CASE;
        DBMS_OUTPUT.PUT_LINE(RPAD(p_titulo, 26) || ' -> executou sem erro');
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE(RPAD(p_titulo, 26) || ' -> ' || SQLERRM);
    END tentar;
BEGIN
    tentar('Periodo invalido', 1);
    tentar('Paciente inexistente', 2);
    tentar('Leitura inexistente', 3);
    tentar('Ingestao sem paciente', 4);
    tentar('Metrica desconhecida', 5);
    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- Q8. Trilha de auditoria das rotinas (inclusive das falhas acima).
-- -----------------------------------------------------------------------------
SELECT routine_name, status, rows_affected,
       TO_CHAR(executed_at, 'DD/MM HH24:MI:SS') AS quando,
       SUBSTR(message, 1, 90) AS mensagem
  FROM routine_execution_log
 ORDER BY id DESC
 FETCH FIRST 15 ROWS ONLY;
