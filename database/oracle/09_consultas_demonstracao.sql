-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 09_consultas_demonstracao.sql - uso pratico dos packages, triggers e Dynamic SQL
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
       p.name                                           AS paciente,
       p.age                                            AS idade,
       pkg_clinico.fn_calcular_score_saude(u.ultima_id) AS score,
       pkg_clinico.fn_rotulo_nivel(pkg_clinico.fn_calcular_score_saude(u.ultima_id)) AS nivel
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
SELECT pkg_clinico.fn_formatar_resumo_paciente(id, 30) AS resumo
  FROM patient
 ORDER BY id;

-- -----------------------------------------------------------------------------
-- Q3. Tempo na faixa (Time in Range) por metrica nos ultimos 30 dias.
-- -----------------------------------------------------------------------------
SELECT name                                                AS paciente,
       pkg_clinico.fn_tempo_na_faixa(id, 'GLUCOSE', 30)    AS glicemia_pct,
       pkg_clinico.fn_tempo_na_faixa(id, 'SPO2', 30)       AS spo2_pct,
       pkg_clinico.fn_tempo_na_faixa(id, 'SYSTOLIC', 30)   AS sistolica_pct,
       pkg_clinico.fn_tempo_na_faixa(id, 'HEART_RATE', 30) AS freq_cardiaca_pct
  FROM patient
 ORDER BY glicemia_pct NULLS LAST;

-- -----------------------------------------------------------------------------
-- Q4. Ultimas leituras de um paciente, formatadas e com score e classificacao
--     de cada sinal - a function e aplicada linha a linha.
-- -----------------------------------------------------------------------------
SELECT pkg_clinico.fn_formatar_leitura(v.id)                        AS leitura,
       pkg_clinico.fn_calcular_score_saude(v.id)                    AS score,
       pkg_clinico.fn_classificar_sinal('GLUCOSE', v.glucose_level) AS glicemia,
       pkg_clinico.fn_classificar_sinal('SPO2', v.spo2)             AS spo2
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
       ROUND(AVG(pkg_clinico.fn_calcular_score_saude(v.id)), 1)        AS score_medio
  FROM vital_reading v
  JOIN patient p ON p.id = v.patient_id
 WHERE v.measured_at >= SYSTIMESTAMP - INTERVAL '7' DAY
 GROUP BY p.name, TRUNC(CAST(v.measured_at AS DATE))
 ORDER BY p.name, TRUNC(CAST(v.measured_at AS DATE));

-- -----------------------------------------------------------------------------
-- Q6. Leituras em que o score caiu abaixo de 60 - candidatas a revisao clinica.
-- -----------------------------------------------------------------------------
SELECT p.name AS paciente, pkg_clinico.fn_formatar_leitura(v.id) AS leitura, pkg_clinico.fn_calcular_score_saude(v.id) AS score
  FROM vital_reading v
  JOIN patient p ON p.id = v.patient_id
 WHERE pkg_clinico.fn_calcular_score_saude(v.id) < 60
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

    pkg_monitoramento.prc_registrar_leitura(
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
                         pkg_clinico.fn_calcular_score_saude(v_leitura) || ' | ' || v_alertas || ' alerta(s) aberto(s)');
    DBMS_OUTPUT.PUT_LINE(pkg_clinico.fn_formatar_leitura(v_leitura));

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

    pkg_relatorios.prc_consolidar_relatorio(v_paciente, 14, v_processados);

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
            WHEN 1 THEN pkg_relatorios.prc_consolidar_relatorio(NULL, 0, v_n);       -- periodo invalido
            WHEN 2 THEN pkg_relatorios.prc_consolidar_relatorio(-1, 30, v_n);        -- paciente inexistente
            WHEN 3 THEN pkg_monitoramento.prc_registrar_alertas_leitura(-1, v_n);    -- leitura inexistente
            WHEN 4 THEN pkg_monitoramento.prc_registrar_leitura(-1, 80, 97, 100, 120, 80, 36.5, NULL, v_r, v_n);
            WHEN 5 THEN v_n := pkg_clinico.fn_tempo_na_faixa(1, 'COLESTEROL', 30); -- metrica desconhecida
            WHEN 6 THEN v_n := pkg_consultas.fn_indicador('GLUCOSE', 'SUM');        -- agregacao fora da lista
            WHEN 7 THEN UPDATE delivery_order SET status = 'PREPARING'               -- pedido ja entregue
                         WHERE order_code = 'SC-2026-0371';
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
    tentar('Agregacao dinamica', 6);
    tentar('Pedido finalizado', 7);
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

-- =============================================================================
-- Fase 7 - packages, Dynamic SQL e triggers
-- =============================================================================
COLUMN grupo        FORMAT A18
COLUMN sql_montado  FORMAT A200
COLUMN operation    FORMAT A12
COLUMN client       FORMAT A24
COLUMN title        FORMAT A40

-- -----------------------------------------------------------------------------
-- K1. Overload do package: score de uma leitura que ainda nao foi gravada
--     (mesma regra da versao por id - reuso dentro do PKG_CLINICO).
-- -----------------------------------------------------------------------------
SELECT pkg_clinico.fn_calcular_score_saude(121, 91.2, 215, 141, 92, 38.1) AS score_simulado,
       pkg_clinico.fn_rotulo_nivel(
           pkg_clinico.fn_calcular_score_saude(121, 91.2, 215, 141, 92, 38.1)) AS nivel
  FROM dual;

-- -----------------------------------------------------------------------------
-- D1. Dynamic SQL (DBMS_SQL + REF CURSOR): leituras de glicemia fora da faixa
--     nos ultimos 7 dias, da mais alta para a mais baixa. So os filtros
--     informados entram no WHERE - veja o texto montado logo abaixo.
-- -----------------------------------------------------------------------------
VARIABLE rc REFCURSOR
BEGIN
    :rc := pkg_consultas.fn_buscar_leituras(
               p_metric_code       => 'GLUCOSE',
               p_somente_alteradas => 'S',
               p_dias              => 7,
               p_ordenar_por       => 'VALOR',
               p_direcao           => 'DESC',
               p_limite            => 10);
END;
/
PRINT rc

SELECT pkg_consultas.fn_ultimo_sql AS sql_montado FROM dual;

-- Mesma function, outra combinacao: um paciente, faixa de SpO2, pior score.
DECLARE
    v_cursor   SYS_REFCURSOR;
    v_id       NUMBER;
    v_paciente VARCHAR2(120);
    v_quando   TIMESTAMP WITH TIME ZONE;
    v_valor    NUMBER;
    v_score    NUMBER;
    v_leitura  VARCHAR2(300);
    v_maria    patient.id%TYPE;
BEGIN
    SELECT id INTO v_maria FROM patient WHERE name = 'Maria Oliveira';

    v_cursor := pkg_consultas.fn_buscar_leituras(
                    p_patient_id  => v_maria,
                    p_metric_code => 'SPO2',
                    p_valor_max   => 94,
                    p_dias        => 30,
                    p_ordenar_por => 'SCORE',
                    p_direcao     => 'ASC',
                    p_limite      => 5);
    LOOP
        FETCH v_cursor INTO v_id, v_paciente, v_quando, v_valor, v_score, v_leitura;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('score ' || LPAD(v_score, 3) || ' | ' || v_leitura);
    END LOOP;
    CLOSE v_cursor;
    DBMS_OUTPUT.PUT_LINE('SQL: ' || pkg_consultas.fn_ultimo_sql);
END;
/

-- -----------------------------------------------------------------------------
-- D2. Dynamic SQL (EXECUTE IMMEDIATE): a agregacao e a metrica mudam o SQL.
-- -----------------------------------------------------------------------------
SELECT name                                                    AS paciente,
       pkg_consultas.fn_indicador('GLUCOSE', 'AVG', id, 30)    AS glic_media,
       pkg_consultas.fn_indicador('GLUCOSE', 'MAX', id, 30)    AS glic_max,
       pkg_consultas.fn_indicador('GLUCOSE', 'STDDEV', id, 30) AS glic_desvio,
       pkg_consultas.fn_indicador('SPO2', 'MIN', id, 30)       AS spo2_min
  FROM patient
 ORDER BY glic_media DESC;

-- -----------------------------------------------------------------------------
-- D3. Dynamic SQL (OPEN ... FOR string USING): painel em tempo real agrupado
--     por paciente (ultimas 24h) e por dia (ultima semana).
-- -----------------------------------------------------------------------------
VARIABLE painel REFCURSOR
EXEC pkg_consultas.prc_painel_tempo_real('PACIENTE', 1, :painel)
PRINT painel

EXEC pkg_consultas.prc_painel_tempo_real('DIA', 7, :painel)
PRINT painel

-- -----------------------------------------------------------------------------
-- T1. Triggers: reconhecer um alerta preenche ACKNOWLEDGED_AT sozinho
--     (TRG_HEALTH_ALERT_RECONHECIMENTO) e gera a linha de auditoria
--     (TRG_HEALTH_ALERT_AUDITORIA). Termina em ROLLBACK.
-- -----------------------------------------------------------------------------
DECLARE
    v_alerta health_alert%ROWTYPE;
BEGIN
    SELECT * INTO v_alerta
      FROM health_alert
     WHERE acknowledged = 0
     ORDER BY id
     FETCH FIRST 1 ROW ONLY;

    pkg_monitoramento.prc_reconhecer_alerta(v_alerta.id);

    SELECT * INTO v_alerta FROM health_alert WHERE id = v_alerta.id;
    DBMS_OUTPUT.PUT_LINE('Alerta ' || v_alerta.id || ' (' || v_alerta.title || ') reconhecido em '
                         || TO_CHAR(v_alerta.acknowledged_at, 'DD/MM/YYYY HH24:MI:SS'));

    FOR a IN (SELECT operation, old_acknowledged, new_acknowledged, client_module
                FROM health_alert_audit
               WHERE alert_id = v_alerta.id
               ORDER BY id) LOOP
        DBMS_OUTPUT.PUT_LINE('  auditoria: ' || RPAD(a.operation, 12) || ' ' || NVL(TO_CHAR(a.old_acknowledged), '-')
                             || ' -> ' || a.new_acknowledged || ' via ' || a.client_module);
    END LOOP;

    ROLLBACK;
END;
/

-- -----------------------------------------------------------------------------
-- Q9. Trilha de auditoria dos alertas (gravada pela trigger) e tempo ate o
--     reconhecimento dos alertas ja tratados.
-- -----------------------------------------------------------------------------
SELECT a.alert_id, a.operation, a.alert_type, a.title,
       TO_CHAR(a.changed_at, 'DD/MM HH24:MI:SS') AS quando,
       a.client_module AS client
  FROM health_alert_audit a
 ORDER BY a.id DESC
 FETCH FIRST 15 ROWS ONLY;

SELECT type,
       COUNT(*) AS reconhecidos,
       ROUND(AVG(EXTRACT(DAY FROM (acknowledged_at - created_at)) * 1440
               + EXTRACT(HOUR FROM (acknowledged_at - created_at)) * 60
               + EXTRACT(MINUTE FROM (acknowledged_at - created_at))), 1) AS minutos_ate_reconhecer
  FROM health_alert
 WHERE acknowledged = 1
 GROUP BY type;
