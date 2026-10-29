-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 06_pkg_consultas.sql - PKG_CONSULTAS: consultas em tempo real (Dynamic SQL)
--
--   FN_BUSCAR_LEITURAS       busca de leituras com filtros opcionais e
--                            ordenacao escolhida pelo usuario
--                            -> DBMS_SQL (bind condicional) + TO_REFCURSOR
--   FN_INDICADOR             agregacao (AVG, MIN, MAX...) de qualquer metrica
--                            -> EXECUTE IMMEDIATE ... INTO ... USING
--   PRC_PAINEL_TEMPO_REAL    painel agrupado por paciente, dia ou hora
--                            -> OPEN cursor FOR string USING
--   FN_ULTIMO_SQL            texto do ultimo comando montado (depuracao)
--
-- Por que Dynamic SQL: a central de monitoramento combina filtros livremente
-- (paciente, metrica, faixa de valor, so leituras alteradas, periodo) e muda a
-- ordenacao e o agrupamento em tempo real. Com SQL estatico isso exigiria um
-- comando por combinacao, ou um unico WHERE cheio de "(:x IS NULL OR ...)" que
-- impede o otimizador de usar os indices. Aqui so entram no texto os filtros
-- realmente informados - cada combinacao ganha o proprio plano de execucao.
--
-- Seguranca (SQL injection):
--   * valores do usuario entram SEMPRE como variaveis bind, nunca concatenados;
--   * identificadores (coluna da metrica, funcao de agregacao, ordenacao) vem
--     de listas brancas - PKG_CLINICO.FN_COLUNA_METRICA e CASEs fechados - e
--     ainda passam por DBMS_ASSERT.SIMPLE_SQL_NAME.
-- Faixas de erro reservadas: -20013 a -20016.
-- =============================================================================

CREATE OR REPLACE PACKAGE pkg_consultas
IS
    -- -------------------------------------------------------------------------
    -- FN_BUSCAR_LEITURAS
    -- Proposito : busca de leituras para a central de monitoramento. Todos os
    --             filtros sao opcionais; so os informados entram no WHERE.
    -- Parametros: p_patient_id        paciente (NULL = todos)
    --             p_metric_code       metrica analisada (HEART_RATE, SPO2...)
    --             p_valor_min/max     faixa de valor da metrica
    --             p_somente_alteradas 'S' = so leituras com a metrica fora da
    --                                 faixa normal de VITAL_REFERENCE_RANGE
    --             p_dias              janela (1 a 365)
    --             p_ordenar_por       DATA | VALOR | SCORE | PACIENTE
    --             p_direcao           ASC | DESC
    --             p_limite            maximo de linhas (1 a 1000)
    -- Retorno   : SYS_REFCURSOR com reading_id, paciente, measured_at,
    --             valor_metrica, score e leitura (texto formatado)
    -- Erros     : -20010 metrica desconhecida | -20013 periodo ou limite
    --             -20014 ordenacao invalida | -20015 filtro exige metrica
    -- -------------------------------------------------------------------------
    FUNCTION fn_buscar_leituras (
        p_patient_id        IN NUMBER   DEFAULT NULL,
        p_metric_code       IN VARCHAR2 DEFAULT NULL,
        p_valor_min         IN NUMBER   DEFAULT NULL,
        p_valor_max         IN NUMBER   DEFAULT NULL,
        p_somente_alteradas IN VARCHAR2 DEFAULT 'N',
        p_dias              IN NUMBER   DEFAULT 7,
        p_ordenar_por       IN VARCHAR2 DEFAULT 'DATA',
        p_direcao           IN VARCHAR2 DEFAULT 'DESC',
        p_limite            IN NUMBER   DEFAULT 50
    ) RETURN SYS_REFCURSOR;

    -- -------------------------------------------------------------------------
    -- FN_INDICADOR
    -- Proposito : calcular um indicador escolhido em tempo de execucao - a
    --             funcao de agregacao e a coluna mudam o proprio texto do SQL.
    -- Parametros: p_metric_code, p_agregacao (AVG | MIN | MAX | STDDEV |
    --             MEDIAN | COUNT), p_patient_id (NULL = populacao), p_dias
    -- Retorno   : valor com 1 casa decimal; NULL sem leituras
    -- Erros     : -20010 metrica | -20013 periodo | -20016 agregacao invalida
    -- -------------------------------------------------------------------------
    FUNCTION fn_indicador (
        p_metric_code IN VARCHAR2,
        p_agregacao   IN VARCHAR2 DEFAULT 'AVG',
        p_patient_id  IN NUMBER   DEFAULT NULL,
        p_dias        IN NUMBER   DEFAULT 30
    ) RETURN NUMBER;

    -- -------------------------------------------------------------------------
    -- PRC_PAINEL_TEMPO_REAL
    -- Proposito : alimentar o painel com leituras, score medio, leituras
    --             criticas (score < 60) e medias dos sinais, agrupados pela
    --             dimensao escolhida.
    -- Parametros: p_agrupar_por IN  PACIENTE | DIA | HORA
    --             p_dias        IN  janela (1 a 365)
    --             p_resultado   OUT SYS_REFCURSOR (grupo, leituras,
    --                               score_medio, leituras_criticas, fc_media,
    --                               spo2_media, glicemia_media, sistolica_media)
    -- Erros     : -20013 periodo | -20014 agrupamento invalido
    -- -------------------------------------------------------------------------
    PROCEDURE prc_painel_tempo_real (
        p_agrupar_por IN  VARCHAR2 DEFAULT 'PACIENTE',
        p_dias        IN  NUMBER   DEFAULT 1,
        p_resultado   OUT SYS_REFCURSOR
    );

    -- Texto do ultimo SQL montado nesta sessao (para depuracao e documentacao).
    FUNCTION fn_ultimo_sql RETURN VARCHAR2;
END pkg_consultas;
/

CREATE OR REPLACE PACKAGE BODY pkg_consultas
IS
    -- Estado de sessao: so existe porque o codigo esta em um package.
    g_ultimo_sql VARCHAR2(4000);

    PROCEDURE validar_periodo (p_dias IN NUMBER)
    IS
    BEGIN
        IF p_dias IS NULL OR p_dias NOT BETWEEN 1 AND 365 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Periodo invalido: informe entre 1 e 365 dias.');
        END IF;
    END validar_periodo;

    -- Coluna da metrica ja validada pela lista branca do PKG_CLINICO.
    FUNCTION coluna_segura (p_metric_code IN VARCHAR2) RETURN VARCHAR2
    IS
    BEGIN
        RETURN DBMS_ASSERT.SIMPLE_SQL_NAME(pkg_clinico.fn_coluna_metrica(p_metric_code));
    END coluna_segura;

    FUNCTION fn_buscar_leituras (
        p_patient_id        IN NUMBER   DEFAULT NULL,
        p_metric_code       IN VARCHAR2 DEFAULT NULL,
        p_valor_min         IN NUMBER   DEFAULT NULL,
        p_valor_max         IN NUMBER   DEFAULT NULL,
        p_somente_alteradas IN VARCHAR2 DEFAULT 'N',
        p_dias              IN NUMBER   DEFAULT 7,
        p_ordenar_por       IN VARCHAR2 DEFAULT 'DATA',
        p_direcao           IN VARCHAR2 DEFAULT 'DESC',
        p_limite            IN NUMBER   DEFAULT 50
    ) RETURN SYS_REFCURSOR
    IS
        c_rotina CONSTANT VARCHAR2(60) := 'PKG_CONSULTAS.FN_BUSCAR_LEITURAS';

        v_coluna    VARCHAR2(30);
        v_alteradas BOOLEAN := UPPER(NVL(p_somente_alteradas, 'N')) = 'S';
        v_ordem     VARCHAR2(60);
        v_direcao   VARCHAR2(4)  := UPPER(NVL(p_direcao, 'DESC'));
        v_sql       VARCHAR2(4000);
        v_cursor    INTEGER;
        v_linhas    INTEGER;
    BEGIN
        validar_periodo(p_dias);
        IF p_limite IS NULL OR p_limite NOT BETWEEN 1 AND 1000 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Limite invalido: informe entre 1 e 1000 linhas.');
        END IF;
        IF v_direcao NOT IN ('ASC', 'DESC') THEN
            RAISE_APPLICATION_ERROR(-20014, 'Direcao invalida: use ASC ou DESC.');
        END IF;

        IF p_metric_code IS NOT NULL THEN
            v_coluna := coluna_segura(p_metric_code);
        ELSIF p_valor_min IS NOT NULL OR p_valor_max IS NOT NULL OR v_alteradas
              OR UPPER(p_ordenar_por) = 'VALOR' THEN
            RAISE_APPLICATION_ERROR(-20015,
                'Filtro por valor, leituras alteradas e ordenacao por valor exigem a metrica.');
        END IF;

        v_ordem := CASE UPPER(NVL(p_ordenar_por, 'DATA'))
                       WHEN 'DATA'     THEN 'v.measured_at'
                       WHEN 'VALOR'    THEN 'v.' || v_coluna
                       WHEN 'SCORE'    THEN 'score'
                       WHEN 'PACIENTE' THEN 'p.name'
                   END;
        IF v_ordem IS NULL THEN
            RAISE_APPLICATION_ERROR(-20014, 'Ordenacao invalida: use DATA, VALOR, SCORE ou PACIENTE.');
        END IF;

        -- Montagem: so entram no texto os filtros informados.
        v_sql := 'SELECT v.id AS reading_id, p.name AS paciente, v.measured_at, '
              || CASE WHEN v_coluna IS NOT NULL THEN 'v.' || v_coluna ELSE 'CAST(NULL AS NUMBER)' END
              || ' AS valor_metrica, pkg_clinico.fn_calcular_score_saude(v.id) AS score,'
              || ' pkg_clinico.fn_formatar_leitura(v.id) AS leitura'
              || ' FROM vital_reading v JOIN patient p ON p.id = v.patient_id'
              || ' WHERE v.measured_at >= SYSTIMESTAMP - NUMTODSINTERVAL(:dias, ''DAY'')';

        IF p_patient_id IS NOT NULL THEN
            v_sql := v_sql || ' AND v.patient_id = :paciente';
        END IF;
        IF p_valor_min IS NOT NULL THEN
            v_sql := v_sql || ' AND v.' || v_coluna || ' >= :valor_min';
        END IF;
        IF p_valor_max IS NOT NULL THEN
            v_sql := v_sql || ' AND v.' || v_coluna || ' <= :valor_max';
        END IF;
        IF v_alteradas THEN
            v_sql := v_sql || ' AND EXISTS (SELECT 1 FROM vital_reference_range r'
                           || ' WHERE r.metric_code = :metrica'
                           || ' AND v.' || v_coluna || ' NOT BETWEEN r.normal_min AND r.normal_max)';
        END IF;

        v_sql := v_sql || ' ORDER BY ' || v_ordem || ' ' || v_direcao || ' NULLS LAST, v.id'
                       || ' FETCH FIRST :limite ROWS ONLY';
        g_ultimo_sql := v_sql;

        -- DBMS_SQL permite ligar so as variaveis que existem no texto montado;
        -- TO_REFCURSOR devolve o resultado como um cursor comum para o chamador
        -- (JDBC, SQL Developer ou outro bloco PL/SQL).
        v_cursor := DBMS_SQL.OPEN_CURSOR;
        DBMS_SQL.PARSE(v_cursor, v_sql, DBMS_SQL.NATIVE);
        DBMS_SQL.BIND_VARIABLE(v_cursor, ':dias', p_dias);
        DBMS_SQL.BIND_VARIABLE(v_cursor, ':limite', p_limite);
        IF p_patient_id IS NOT NULL THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':paciente', p_patient_id);
        END IF;
        IF p_valor_min IS NOT NULL THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':valor_min', p_valor_min);
        END IF;
        IF p_valor_max IS NOT NULL THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':valor_max', p_valor_max);
        END IF;
        IF v_alteradas THEN
            DBMS_SQL.BIND_VARIABLE(v_cursor, ':metrica', UPPER(TRIM(p_metric_code)));
        END IF;

        v_linhas := DBMS_SQL.EXECUTE(v_cursor);

        pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_sucesso, 0, v_sql);
        RETURN DBMS_SQL.TO_REFCURSOR(v_cursor);
    EXCEPTION
        WHEN OTHERS THEN
            IF v_cursor IS NOT NULL AND DBMS_SQL.IS_OPEN(v_cursor) THEN
                DBMS_SQL.CLOSE_CURSOR(v_cursor);
            END IF;
            pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_erro, 0, SQLERRM);
            RAISE;
    END fn_buscar_leituras;

    FUNCTION fn_indicador (
        p_metric_code IN VARCHAR2,
        p_agregacao   IN VARCHAR2 DEFAULT 'AVG',
        p_patient_id  IN NUMBER   DEFAULT NULL,
        p_dias        IN NUMBER   DEFAULT 30
    ) RETURN NUMBER
    IS
        v_coluna    VARCHAR2(30) := coluna_segura(p_metric_code);
        v_agregacao VARCHAR2(4000) := UPPER(TRIM(p_agregacao)); -- validada abaixo
        v_sql       VARCHAR2(1000);
        v_valor     NUMBER;
    BEGIN
        validar_periodo(p_dias);
        IF v_agregacao NOT IN ('AVG', 'MIN', 'MAX', 'STDDEV', 'MEDIAN', 'COUNT') OR v_agregacao IS NULL THEN
            RAISE_APPLICATION_ERROR(-20016,
                'Agregacao invalida: use AVG, MIN, MAX, STDDEV, MEDIAN ou COUNT.');
        END IF;

        v_sql := 'SELECT ROUND(' || v_agregacao || '(' || v_coluna || '), 1)'
              || ' FROM vital_reading'
              || ' WHERE measured_at >= SYSTIMESTAMP - NUMTODSINTERVAL(:dias, ''DAY'')';

        IF p_patient_id IS NULL THEN
            g_ultimo_sql := v_sql;
            EXECUTE IMMEDIATE v_sql INTO v_valor USING p_dias;
        ELSE
            v_sql := v_sql || ' AND patient_id = :paciente';
            g_ultimo_sql := v_sql;
            EXECUTE IMMEDIATE v_sql INTO v_valor USING p_dias, p_patient_id;
        END IF;

        RETURN v_valor;
    END fn_indicador;

    PROCEDURE prc_painel_tempo_real (
        p_agrupar_por IN  VARCHAR2 DEFAULT 'PACIENTE',
        p_dias        IN  NUMBER   DEFAULT 1,
        p_resultado   OUT SYS_REFCURSOR
    )
    IS
        c_rotina CONSTANT VARCHAR2(60) := 'PKG_CONSULTAS.PRC_PAINEL_TEMPO_REAL';
        v_grupo  VARCHAR2(200);
        v_sql    VARCHAR2(2000);
    BEGIN
        validar_periodo(p_dias);

        v_grupo := CASE UPPER(NVL(p_agrupar_por, 'PACIENTE'))
                       WHEN 'PACIENTE' THEN 'p.name'
                       WHEN 'DIA'      THEN 'TO_CHAR(v.measured_at AT TIME ZONE ''America/Sao_Paulo'', ''DD/MM/YYYY'')'
                       WHEN 'HORA'     THEN 'TO_CHAR(v.measured_at AT TIME ZONE ''America/Sao_Paulo'', ''DD/MM HH24'') || ''h'''
                   END;
        IF v_grupo IS NULL THEN
            RAISE_APPLICATION_ERROR(-20014, 'Agrupamento invalido: use PACIENTE, DIA ou HORA.');
        END IF;

        v_sql := 'SELECT grupo, COUNT(*) AS leituras,'
              || ' ROUND(AVG(score), 1) AS score_medio,'
              || ' COUNT(CASE WHEN score < 60 THEN 1 END) AS leituras_criticas,'
              || ' ROUND(AVG(heart_rate), 1) AS fc_media,'
              || ' ROUND(AVG(spo2), 1) AS spo2_media,'
              || ' ROUND(AVG(glucose_level), 1) AS glicemia_media,'
              || ' ROUND(AVG(bp_systolic), 1) AS sistolica_media'
              || ' FROM (SELECT ' || v_grupo || ' AS grupo, MIN(v.measured_at) OVER (PARTITION BY '
              || v_grupo || ') AS inicio, pkg_clinico.fn_calcular_score_saude(v.id) AS score,'
              || ' v.heart_rate, v.spo2, v.glucose_level, v.bp_systolic'
              || ' FROM vital_reading v JOIN patient p ON p.id = v.patient_id'
              || ' WHERE v.measured_at >= SYSTIMESTAMP - NUMTODSINTERVAL(:dias, ''DAY''))'
              || ' GROUP BY grupo, inicio'
              || ' ORDER BY ' || CASE WHEN UPPER(NVL(p_agrupar_por, 'PACIENTE')) = 'PACIENTE'
                                      THEN 'score_medio' ELSE 'inicio' END;
        g_ultimo_sql := v_sql;

        OPEN p_resultado FOR v_sql USING p_dias;

        pkg_auditoria.prc_log_execucao(c_rotina, pkg_auditoria.c_sucesso, 0,
            'Agrupado por ' || UPPER(p_agrupar_por) || ', ' || p_dias || ' dia(s).');
    END prc_painel_tempo_real;

    FUNCTION fn_ultimo_sql RETURN VARCHAR2
    IS
    BEGIN
        RETURN g_ultimo_sql;
    END fn_ultimo_sql;
END pkg_consultas;
/
