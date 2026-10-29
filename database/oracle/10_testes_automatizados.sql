-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 10_testes_automatizados.sql - testes de unidade dos packages e triggers
--
-- Executado pelo pipeline CI/CD depois do instalar.sql. Cada verificacao
-- imprime [OK] ou [FALHA]; se houver qualquer falha o bloco termina com
-- ORA-20999 e o SQL*Plus sai com codigo de erro - o job do pipeline quebra.
-- Tudo o que os testes gravam e desfeito com ROLLBACK no fim (so o log das
-- rotinas, em transacao autonoma, permanece).
-- =============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK OFF
WHENEVER SQLERROR EXIT FAILURE ROLLBACK

DECLARE
    v_total    PLS_INTEGER := 0;
    v_falhas   PLS_INTEGER := 0;

    v_n        NUMBER;
    v_paciente patient.id%TYPE;
    v_leitura  vital_reading.id%TYPE;
    v_alertas  NUMBER;
    v_alerta   health_alert%ROWTYPE;
    v_pedido   delivery_order%ROWTYPE;
    v_quando   TIMESTAMP WITH TIME ZONE;

    PROCEDURE verificar (p_teste VARCHAR2, p_condicao BOOLEAN, p_detalhe VARCHAR2 DEFAULT NULL) IS
    BEGIN
        v_total := v_total + 1;
        IF NVL(p_condicao, FALSE) THEN
            DBMS_OUTPUT.PUT_LINE('[OK]    ' || p_teste);
        ELSE
            v_falhas := v_falhas + 1;
            DBMS_OUTPUT.PUT_LINE('[FALHA] ' || p_teste || CASE WHEN p_detalhe IS NOT NULL THEN ' - ' || p_detalhe END);
        END IF;
    END verificar;
BEGIN
    DBMS_OUTPUT.PUT_LINE('== Objetos');
    SELECT COUNT(*) INTO v_n
      FROM user_objects
     WHERE object_type IN ('PACKAGE', 'PACKAGE BODY')
       AND object_name IN ('PKG_AUDITORIA', 'PKG_CLINICO', 'PKG_MONITORAMENTO', 'PKG_RELATORIOS', 'PKG_CONSULTAS')
       AND status = 'VALID';
    verificar('5 packages com spec e body validos', v_n = 10, v_n || ' objetos validos');

    SELECT COUNT(*) INTO v_n
      FROM user_triggers
     WHERE trigger_name IN ('TRG_HEALTH_ALERT_RECONHECIMENTO', 'TRG_HEALTH_ALERT_AUDITORIA',
                            'TRG_DELIVERY_ORDER_STATUS', 'TRG_PATIENT_ATUALIZACAO')
       AND status = 'ENABLED';
    verificar('4 triggers habilitadas', v_n = 4, v_n || ' habilitadas');

    SELECT COUNT(*) INTO v_n FROM user_objects WHERE status <> 'VALID';
    verificar('nenhum objeto invalido no esquema', v_n = 0, v_n || ' invalidos');

    DBMS_OUTPUT.PUT_LINE('== PKG_CLINICO');
    verificar('glicemia 100 e NORMAL',     pkg_clinico.fn_classificar_sinal('GLUCOSE', 100) = pkg_clinico.c_normal);
    verificar('glicemia 150 e ATTENTION',  pkg_clinico.fn_classificar_sinal('glucose', 150) = pkg_clinico.c_atencao);
    verificar('glicemia 250 e CRITICAL',   pkg_clinico.fn_classificar_sinal('GLUCOSE', 250) = pkg_clinico.c_critico);
    verificar('valor nulo nao e classificado', pkg_clinico.fn_classificar_sinal('GLUCOSE', NULL) IS NULL);
    verificar('coluna da metrica GLUCOSE', pkg_clinico.fn_coluna_metrica('glucose') = 'GLUCOSE_LEVEL');

    v_n := pkg_clinico.fn_calcular_score_saude(72, 98.5, 104, 118, 78, 36.6);
    verificar('score de sinais normais = 100', v_n = 100, 'score ' || v_n);
    -- FC critica -18, SpO2 atencao -9, glicemia critica -22, sistolica critica
    -- -18, diastolica critica -10, temperatura atencao -4 => 19 (mesmo valor
    -- do HealthScoreCalculator).
    v_n := pkg_clinico.fn_calcular_score_saude(121, 91.2, 215, 141, 92, 38.1);
    verificar('score de leitura critica = 19', v_n = 19, 'score ' || v_n);
    verificar('score de leitura inexistente e NULL', pkg_clinico.fn_calcular_score_saude(-1) IS NULL);
    verificar('rotulo de 92 = EXCELENTE', pkg_clinico.fn_rotulo_nivel(92) = 'EXCELENTE');
    verificar('rotulo de 19 = CRITICO',   pkg_clinico.fn_rotulo_nivel(19) = 'CRITICO');
    verificar('rotulo sem score = SEM DADOS', pkg_clinico.fn_rotulo_nivel(NULL) = 'SEM DADOS');

    DBMS_OUTPUT.PUT_LINE('== PKG_MONITORAMENTO');
    SELECT id INTO v_paciente FROM patient WHERE name = 'Felipe Meira';
    UPDATE health_alert SET acknowledged = 1 WHERE patient_id = v_paciente AND acknowledged = 0;

    pkg_monitoramento.prc_registrar_leitura(v_paciente, 121, 91.2, 215, 141, 92, 38.1,
                                            NULL, v_leitura, v_alertas);
    verificar('leitura critica abre 6 alertas', v_alertas = 6, v_alertas || ' alertas');
    verificar('overload por id = overload por valores',
              pkg_clinico.fn_calcular_score_saude(v_leitura) = 19);
    verificar('leitura formatada no padrao brasileiro',
              pkg_clinico.fn_formatar_leitura(v_leitura) LIKE '%SpO2 91,2%; Glicemia 215 mg/dL%');

    pkg_monitoramento.prc_registrar_leitura(v_paciente, 121, 91.2, 215, 141, 92, 38.1,
                                            NULL, v_leitura, v_alertas);
    verificar('alerta aberto nao e duplicado', v_alertas = 0, v_alertas || ' alertas');

    DBMS_OUTPUT.PUT_LINE('== Triggers');
    SELECT * INTO v_alerta
      FROM health_alert
     WHERE patient_id = v_paciente AND acknowledged = 0 AND metric = 'Glicemia';

    SELECT COUNT(*) INTO v_n
      FROM health_alert_audit WHERE alert_id = v_alerta.id AND operation = 'CRIACAO';
    verificar('auditoria registra a criacao do alerta', v_n = 1);

    pkg_monitoramento.prc_reconhecer_alerta(v_alerta.id);
    SELECT * INTO v_alerta FROM health_alert WHERE id = v_alerta.id;
    verificar('reconhecimento carimba acknowledged_at', v_alerta.acknowledged_at IS NOT NULL);

    SELECT COUNT(*) INTO v_n
      FROM health_alert_audit WHERE alert_id = v_alerta.id AND operation = 'RECONHECIDO';
    verificar('auditoria registra o reconhecimento', v_n = 1);

    UPDATE health_alert SET acknowledged = 0 WHERE id = v_alerta.id;
    SELECT * INTO v_alerta FROM health_alert WHERE id = v_alerta.id;
    verificar('reabertura limpa acknowledged_at', v_alerta.acknowledged_at IS NULL);

    DELETE FROM health_alert WHERE id = v_alerta.id;
    SELECT COUNT(*) INTO v_n
      FROM health_alert_audit WHERE alert_id = v_alerta.id;
    verificar('trilha sobrevive a exclusao (4 eventos)', v_n = 4, v_n || ' eventos');

    SELECT * INTO v_pedido FROM delivery_order WHERE order_code = 'SC-2026-0402';
    UPDATE delivery_order SET status = 'PREPARING' WHERE order_code = 'SC-2026-0402';
    SELECT updated_at INTO v_quando FROM delivery_order WHERE order_code = 'SC-2026-0402';
    verificar('transicao valida carimba updated_at', v_quando > v_pedido.updated_at);

    UPDATE delivery_order SET status = 'CANCELLED' WHERE order_code = 'SC-2026-0402';
    SELECT eta_minutes INTO v_n FROM delivery_order WHERE order_code = 'SC-2026-0402';
    verificar('pedido cancelado tem ETA zerado', v_n = 0, 'eta ' || v_n);

    SELECT updated_at INTO v_quando FROM patient WHERE id = v_paciente;
    UPDATE patient SET age = age WHERE id = v_paciente;
    SELECT COUNT(*) INTO v_n FROM patient WHERE id = v_paciente AND updated_at > v_quando;
    verificar('alteracao do prontuario carimba updated_at', v_n = 1);

    ROLLBACK;

    DBMS_OUTPUT.PUT_LINE('== ' || v_total || ' verificacoes, ' || v_falhas || ' falha(s)');
    IF v_falhas > 0 THEN
        RAISE_APPLICATION_ERROR(-20999, v_falhas || ' teste(s) falharam.');
    END IF;
END;
/

-- Segundo bloco: Dynamic SQL, relatorios e codigos de erro.
DECLARE
    v_total    PLS_INTEGER := 0;
    v_falhas   PLS_INTEGER := 0;

    v_n        NUMBER;
    v_paciente patient.id%TYPE;
    v_cursor   SYS_REFCURSOR;
    v_id       NUMBER;
    v_nome     VARCHAR2(120);
    v_quando   TIMESTAMP WITH TIME ZONE;
    v_valor    NUMBER;
    v_score    NUMBER;
    v_texto    VARCHAR2(300);
    v_linhas   PLS_INTEGER;
    v_fora     PLS_INTEGER;
    v_sql      VARCHAR2(4000);

    PROCEDURE verificar (p_teste VARCHAR2, p_condicao BOOLEAN, p_detalhe VARCHAR2 DEFAULT NULL) IS
    BEGIN
        v_total := v_total + 1;
        IF NVL(p_condicao, FALSE) THEN
            DBMS_OUTPUT.PUT_LINE('[OK]    ' || p_teste);
        ELSE
            v_falhas := v_falhas + 1;
            DBMS_OUTPUT.PUT_LINE('[FALHA] ' || p_teste || CASE WHEN p_detalhe IS NOT NULL THEN ' - ' || p_detalhe END);
        END IF;
    END verificar;

    PROCEDURE esperar_erro (p_teste VARCHAR2, p_codigo NUMBER, p_caso PLS_INTEGER) IS
        v_dummy NUMBER;
        v_rc    SYS_REFCURSOR;
    BEGIN
        SAVEPOINT sp_erro;
        CASE p_caso
            WHEN 1 THEN pkg_relatorios.prc_consolidar_relatorio(NULL, 0, v_dummy);
            WHEN 2 THEN pkg_relatorios.prc_consolidar_relatorio(-1, 30, v_dummy);
            WHEN 3 THEN pkg_monitoramento.prc_registrar_alertas_leitura(-1, v_dummy);
            WHEN 4 THEN pkg_monitoramento.prc_reconhecer_alerta(-1);
            WHEN 5 THEN v_dummy := pkg_clinico.fn_tempo_na_faixa(1, 'COLESTEROL', 30);
            WHEN 6 THEN v_rc := pkg_consultas.fn_buscar_leituras(p_ordenar_por => 'DATA; DROP TABLE patient');
            WHEN 7 THEN v_rc := pkg_consultas.fn_buscar_leituras(p_metric_code => 'GLUCOSE_LEVEL) OR (1=1');
            WHEN 8 THEN v_dummy := pkg_consultas.fn_indicador('GLUCOSE', 'SUM(1)) FROM dual --');
            WHEN 9 THEN v_rc := pkg_consultas.fn_buscar_leituras(p_somente_alteradas => 'S');
            WHEN 10 THEN UPDATE delivery_order SET status = 'IN_TRANSIT' WHERE order_code = 'SC-2026-0371';
            WHEN 11 THEN UPDATE delivery_order SET status = 'DELIVERED' WHERE order_code = 'SC-2026-0402';
            WHEN 12 THEN pkg_auditoria.prc_expurgar_logs(7, v_dummy);
        END CASE;
        ROLLBACK TO sp_erro;
        verificar(p_teste, FALSE, 'executou sem erro; esperado ORA' || p_codigo);
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK TO sp_erro;
            verificar(p_teste, SQLCODE = p_codigo, 'recebido ' || SQLERRM);
    END esperar_erro;
BEGIN
    DBMS_OUTPUT.PUT_LINE('== PKG_CONSULTAS (Dynamic SQL)');
    v_cursor := pkg_consultas.fn_buscar_leituras(p_metric_code => 'GLUCOSE', p_somente_alteradas => 'S',
                                                 p_dias => 30, p_ordenar_por => 'VALOR', p_limite => 1000);
    v_sql := pkg_consultas.fn_ultimo_sql;
    v_linhas := 0;
    v_fora   := 0;
    LOOP
        FETCH v_cursor INTO v_id, v_nome, v_quando, v_valor, v_score, v_texto;
        EXIT WHEN v_cursor%NOTFOUND;
        v_linhas := v_linhas + 1;
        IF pkg_clinico.fn_classificar_sinal('GLUCOSE', v_valor) <> pkg_clinico.c_normal THEN
            v_fora := v_fora + 1;
        END IF;
    END LOOP;
    CLOSE v_cursor;
    verificar('busca dinamica devolve leituras alteradas', v_linhas > 0, v_linhas || ' linhas');
    verificar('todas as leituras devolvidas estao fora da faixa', v_fora = v_linhas);
    verificar('SQL montado so tem os filtros informados',
              INSTR(v_sql, ':metrica') > 0 AND INSTR(v_sql, ':paciente') = 0 AND INSTR(v_sql, ':valor_min') = 0,
              v_sql);

    SELECT COUNT(*) INTO v_n
      FROM vital_reading
     WHERE glucose_level NOT BETWEEN 70 AND 120
       AND measured_at >= SYSTIMESTAMP - INTERVAL '30' DAY;
    verificar('busca dinamica = consulta estatica equivalente', v_n = v_linhas, v_n || ' x ' || v_linhas);

    SELECT id INTO v_paciente FROM patient WHERE name = 'Joao Silva';
    SELECT ROUND(AVG(glucose_level), 1) INTO v_n
      FROM vital_reading
     WHERE patient_id = v_paciente AND measured_at >= SYSTIMESTAMP - INTERVAL '30' DAY;
    verificar('indicador dinamico AVG = media estatica',
              pkg_consultas.fn_indicador('GLUCOSE', 'avg', v_paciente, 30) = v_n);
    verificar('indicador dinamico COUNT da populacao > 0',
              pkg_consultas.fn_indicador('HEART_RATE', 'COUNT', NULL, 30) > 0);

    pkg_consultas.prc_painel_tempo_real('PACIENTE', 30, v_cursor);
    v_linhas := 0;
    LOOP
        FETCH v_cursor INTO v_texto, v_n, v_score, v_valor, v_valor, v_valor, v_valor, v_valor;
        EXIT WHEN v_cursor%NOTFOUND;
        v_linhas := v_linhas + 1;
    END LOOP;
    CLOSE v_cursor;
    verificar('painel por paciente tem 5 grupos', v_linhas = 5, v_linhas || ' grupos');

    DBMS_OUTPUT.PUT_LINE('== PKG_RELATORIOS');
    pkg_relatorios.prc_consolidar_relatorio(v_paciente, 14, v_n);
    verificar('consolida 1 paciente', v_n = 1);
    SELECT COUNT(*) INTO v_n FROM patient_report WHERE patient_id = v_paciente AND period_days = 14;
    verificar('relatorio gravado em PATIENT_REPORT', v_n = 1);

    DBMS_OUTPUT.PUT_LINE('== Codigos de erro');
    esperar_erro('periodo invalido -> -20003',           -20003, 1);
    esperar_erro('paciente inexistente -> -20004',       -20004, 2);
    esperar_erro('leitura inexistente -> -20001',        -20001, 3);
    esperar_erro('alerta inexistente -> -20002',         -20002, 4);
    esperar_erro('metrica desconhecida -> -20010',       -20010, 5);
    esperar_erro('injecao na ordenacao -> -20014',       -20014, 6);
    esperar_erro('injecao na metrica -> -20010',         -20010, 7);
    esperar_erro('injecao na agregacao -> -20016',       -20016, 8);
    esperar_erro('filtro sem metrica -> -20015',         -20015, 9);
    esperar_erro('pedido entregue e final -> -20020',    -20020, 10);
    esperar_erro('pular etapa logistica -> -20020',      -20020, 11);
    esperar_erro('retencao de log < 30 dias -> -20008',  -20008, 12);

    ROLLBACK;

    DBMS_OUTPUT.PUT_LINE('== ' || v_total || ' verificacoes, ' || v_falhas || ' falha(s)');
    IF v_falhas > 0 THEN
        RAISE_APPLICATION_ERROR(-20999, v_falhas || ' teste(s) falharam.');
    END IF;
END;
/
