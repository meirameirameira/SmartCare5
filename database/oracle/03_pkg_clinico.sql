-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 03_pkg_clinico.sql - PKG_CLINICO: regras clinicas reutilizaveis
--
--   FN_COLUNA_METRICA            codigo da metrica -> coluna de VITAL_READING
--   FN_CLASSIFICAR_SINAL         classifica um valor contra a faixa de referencia
--   FN_CALCULAR_SCORE_SAUDE      [indicador] score 0-100 (2 versoes - overload:
--                                por id de leitura ou pelos valores medidos)
--   FN_TEMPO_NA_FAIXA            [indicador] % de leituras na faixa normal (TIR)
--   FN_ROTULO_NIVEL              converte o score no rotulo exibido ao usuario
--   FN_FORMATAR_LEITURA          [dado formatado] leitura em uma linha legivel
--   FN_FORMATAR_RESUMO_PACIENTE  [dado formatado] resumo clinico do paciente
--
-- Na Fase 6 eram functions avulsas; agrupadas aqui, compartilham tipos,
-- constantes e rotinas privadas (a classificacao contra uma faixa ja lida),
-- e sao compiladas, versionadas e concedidas (GRANT EXECUTE) como uma unidade.
--
-- Todas recebem apenas parametros IN, devolvem o resultado via RETURN e nao
-- executam DML - por isso podem ser chamadas diretamente em SELECT.
-- Faixas de erro reservadas: -20010 a -20019.
-- =============================================================================

CREATE OR REPLACE PACKAGE pkg_clinico
IS
    -- Resultados da classificacao de um sinal vital.
    c_normal    CONSTANT VARCHAR2(10) := 'NORMAL';
    c_atencao   CONSTANT VARCHAR2(10) := 'ATTENTION';
    c_critico   CONSTANT VARCHAR2(10) := 'CRITICAL';

    -- -------------------------------------------------------------------------
    -- FN_COLUNA_METRICA
    -- Proposito : traduzir o codigo da metrica no nome da coluna que a guarda
    --             em VITAL_READING. E a "lista branca" usada pelo Dynamic SQL
    --             do PKG_CONSULTAS: nenhum texto vindo do usuario vira
    --             identificador SQL sem passar por aqui.
    -- Retorno   : HEART_RATE, SPO2, GLUCOSE_LEVEL, BP_SYSTOLIC, BP_DIASTOLIC
    --             ou TEMPERATURE
    -- Erros     : -20010 metrica desconhecida
    -- -------------------------------------------------------------------------
    FUNCTION fn_coluna_metrica (p_metric_code IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC;

    -- -------------------------------------------------------------------------
    -- FN_CLASSIFICAR_SINAL
    -- Proposito : dizer se um valor medido esta NORMAL, em ATTENTION ou
    --             CRITICAL segundo a tabela VITAL_REFERENCE_RANGE.
    -- Parametros: p_metric_code - HEART_RATE, SPO2, GLUCOSE, SYSTOLIC,
    --                             DIASTOLIC ou TEMPERATURE (sem distincao de caixa)
    --             p_valor       - valor medido
    -- Retorno   : c_normal | c_atencao | c_critico; NULL quando p_valor e NULL
    -- Erros     : -20010 metrica sem faixa cadastrada
    -- -------------------------------------------------------------------------
    FUNCTION fn_classificar_sinal (
        p_metric_code IN VARCHAR2,
        p_valor       IN NUMBER
    ) RETURN VARCHAR2;

    -- -------------------------------------------------------------------------
    -- FN_CALCULAR_SCORE_SAUDE  (indicador)
    -- Proposito : converter uma leitura em um score de 0 a 100. Cada metrica
    --             fora da faixa normal desconta pontos: o peso inteiro quando
    --             critica, 40% do peso quando em atencao. E a mesma regra do
    --             HealthScoreCalculator (Java) e do HealthScoreEngine (Flutter).
    -- Versao 1  : p_reading_id - leitura gravada em VITAL_READING. Devolve
    --             NULL se a leitura nao existe (permite uso em LEFT JOIN).
    -- Versao 2  : os seis valores medidos - calcula o score de uma leitura que
    --             ainda nao foi gravada (simulacao, validacao do gateway).
    -- Erros     : -20011 falha inesperada no calculo
    -- -------------------------------------------------------------------------
    FUNCTION fn_calcular_score_saude (p_reading_id IN NUMBER) RETURN NUMBER;

    FUNCTION fn_calcular_score_saude (
        p_heart_rate  IN NUMBER,
        p_spo2        IN NUMBER,
        p_glucose     IN NUMBER,
        p_systolic    IN NUMBER,
        p_diastolic   IN NUMBER,
        p_temperature IN NUMBER
    ) RETURN NUMBER;

    -- -------------------------------------------------------------------------
    -- FN_TEMPO_NA_FAIXA  (indicador)
    -- Proposito : "Time in Range" - percentual das leituras do periodo em que
    --             a metrica ficou dentro da faixa normal. Para glicemia e o
    --             indicador recomendado no acompanhamento de diabeticos.
    -- Parametros: p_patient_id, p_metric_code, p_dias (janela a partir de agora)
    -- Retorno   : percentual com 1 casa decimal (0 a 100); NULL sem leituras
    -- Erros     : -20010 metrica desconhecida | -20012 periodo invalido
    -- -------------------------------------------------------------------------
    FUNCTION fn_tempo_na_faixa (
        p_patient_id  IN NUMBER,
        p_metric_code IN VARCHAR2,
        p_dias        IN NUMBER DEFAULT 30
    ) RETURN NUMBER;

    -- -------------------------------------------------------------------------
    -- FN_ROTULO_NIVEL
    -- Retorno   : EXCELENTE | BOM | MODERADO | ATENCAO | CRITICO | SEM DADOS
    -- -------------------------------------------------------------------------
    FUNCTION fn_rotulo_nivel (p_score IN NUMBER) RETURN VARCHAR2 DETERMINISTIC;

    -- -------------------------------------------------------------------------
    -- FN_FORMATAR_LEITURA  (dado formatado)
    -- Proposito : leitura em uma unica linha, no padrao brasileiro (data
    --             dd/mm/aaaa, horario de Brasilia, virgula decimal).
    -- Retorno   : ex. '02/10/2026 14:30 - FC 78 bpm; SpO2 97,0%; Glicemia 104
    --             mg/dL; PA 118/78 mmHg; Temp. 36,6 C'; NULL se nao existe
    -- -------------------------------------------------------------------------
    FUNCTION fn_formatar_leitura (p_reading_id IN NUMBER) RETURN VARCHAR2;

    -- -------------------------------------------------------------------------
    -- FN_FORMATAR_RESUMO_PACIENTE  (dado formatado)
    -- Proposito : resumo clinico textual exibido no relatorio do app, no
    --             painel administrativo e gravado em PATIENT_REPORT.
    -- Retorno   : texto de ate 1000 caracteres
    -- Erros     : -20004 paciente inexistente
    -- -------------------------------------------------------------------------
    FUNCTION fn_formatar_resumo_paciente (
        p_patient_id IN NUMBER,
        p_dias       IN NUMBER DEFAULT 30
    ) RETURN VARCHAR2;
END pkg_clinico;
/

CREATE OR REPLACE PACKAGE BODY pkg_clinico
IS
    c_decimal_br CONSTANT VARCHAR2(40) := 'NLS_NUMERIC_CHARACTERS='',.''';

    -- Privada: classifica um valor contra uma faixa ja carregada, sem nova
    -- consulta. Usada pelo score, que percorre as seis faixas de uma vez.
    FUNCTION classificar (
        p_valor IN NUMBER,
        p_faixa IN vital_reference_range%ROWTYPE
    ) RETURN VARCHAR2
    IS
    BEGIN
        IF p_valor IS NULL THEN
            RETURN NULL;
        ELSIF p_valor BETWEEN p_faixa.normal_min AND p_faixa.normal_max THEN
            RETURN c_normal;
        ELSIF p_valor BETWEEN p_faixa.attention_min AND p_faixa.attention_max THEN
            RETURN c_atencao;
        END IF;
        RETURN c_critico;
    END classificar;

    FUNCTION fn_coluna_metrica (p_metric_code IN VARCHAR2) RETURN VARCHAR2 DETERMINISTIC
    IS
        v_coluna VARCHAR2(30);
    BEGIN
        v_coluna := CASE UPPER(TRIM(p_metric_code))
                        WHEN 'HEART_RATE'  THEN 'HEART_RATE'
                        WHEN 'SPO2'        THEN 'SPO2'
                        WHEN 'GLUCOSE'     THEN 'GLUCOSE_LEVEL'
                        WHEN 'SYSTOLIC'    THEN 'BP_SYSTOLIC'
                        WHEN 'DIASTOLIC'   THEN 'BP_DIASTOLIC'
                        WHEN 'TEMPERATURE' THEN 'TEMPERATURE'
                    END;

        IF v_coluna IS NULL THEN
            RAISE_APPLICATION_ERROR(-20010, 'Metrica desconhecida: ' || NVL(p_metric_code, '(nula)'));
        END IF;
        RETURN v_coluna;
    END fn_coluna_metrica;

    FUNCTION fn_classificar_sinal (
        p_metric_code IN VARCHAR2,
        p_valor       IN NUMBER
    ) RETURN VARCHAR2
    IS
        v_faixa vital_reference_range%ROWTYPE;
    BEGIN
        IF p_valor IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT *
          INTO v_faixa
          FROM vital_reference_range
         WHERE metric_code = UPPER(TRIM(p_metric_code));

        RETURN classificar(p_valor, v_faixa);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Metrica sem faixa de referencia cadastrada: ' || NVL(p_metric_code, '(nula)'));
    END fn_classificar_sinal;

    FUNCTION fn_calcular_score_saude (
        p_heart_rate  IN NUMBER,
        p_spo2        IN NUMBER,
        p_glucose     IN NUMBER,
        p_systolic    IN NUMBER,
        p_diastolic   IN NUMBER,
        p_temperature IN NUMBER
    ) RETURN NUMBER
    IS
        v_score  NUMBER := 100;
        v_status VARCHAR2(10);
    BEGIN
        FOR f IN (SELECT * FROM vital_reference_range) LOOP
            v_status := classificar(
                CASE f.metric_code
                    WHEN 'HEART_RATE'  THEN p_heart_rate
                    WHEN 'SPO2'        THEN p_spo2
                    WHEN 'GLUCOSE'     THEN p_glucose
                    WHEN 'SYSTOLIC'    THEN p_systolic
                    WHEN 'DIASTOLIC'   THEN p_diastolic
                    WHEN 'TEMPERATURE' THEN p_temperature
                END,
                f);

            IF v_status = c_atencao THEN
                v_score := v_score - ROUND(f.weight * 0.4);
            ELSIF v_status = c_critico THEN
                v_score := v_score - f.weight;
            END IF;
        END LOOP;

        RETURN GREATEST(0, LEAST(100, v_score));
    EXCEPTION
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20011, 'Falha ao calcular o score: ' || SQLERRM);
    END fn_calcular_score_saude;

    FUNCTION fn_calcular_score_saude (p_reading_id IN NUMBER) RETURN NUMBER
    IS
        v_leitura vital_reading%ROWTYPE;
    BEGIN
        IF p_reading_id IS NULL THEN
            RETURN NULL;
        END IF;

        SELECT * INTO v_leitura FROM vital_reading WHERE id = p_reading_id;

        -- Reuso: a regra fica em um unico lugar, a versao por valores.
        RETURN fn_calcular_score_saude(v_leitura.heart_rate, v_leitura.spo2, v_leitura.glucose_level,
                                       v_leitura.bp_systolic, v_leitura.bp_diastolic, v_leitura.temperature);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL; -- leitura inexistente
    END fn_calcular_score_saude;

    FUNCTION fn_tempo_na_faixa (
        p_patient_id  IN NUMBER,
        p_metric_code IN VARCHAR2,
        p_dias        IN NUMBER DEFAULT 30
    ) RETURN NUMBER
    IS
        v_codigo  vital_reference_range.metric_code%TYPE := UPPER(TRIM(p_metric_code));
        v_min     vital_reference_range.normal_min%TYPE;
        v_max     vital_reference_range.normal_max%TYPE;
        v_total   PLS_INTEGER;
        v_normais PLS_INTEGER;
    BEGIN
        IF p_dias IS NULL OR p_dias <= 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Periodo invalido: informe um numero de dias positivo.');
        END IF;

        SELECT normal_min, normal_max
          INTO v_min, v_max
          FROM vital_reference_range
         WHERE metric_code = v_codigo;

        SELECT COUNT(*),
               NVL(SUM(CASE WHEN valor BETWEEN v_min AND v_max THEN 1 ELSE 0 END), 0)
          INTO v_total, v_normais
          FROM (SELECT CASE v_codigo
                           WHEN 'HEART_RATE'  THEN heart_rate
                           WHEN 'SPO2'        THEN spo2
                           WHEN 'GLUCOSE'     THEN glucose_level
                           WHEN 'SYSTOLIC'    THEN bp_systolic
                           WHEN 'DIASTOLIC'   THEN bp_diastolic
                           WHEN 'TEMPERATURE' THEN temperature
                       END AS valor
                  FROM vital_reading
                 WHERE patient_id  = p_patient_id
                   AND measured_at >= SYSTIMESTAMP - NUMTODSINTERVAL(p_dias, 'DAY'));

        IF v_total = 0 THEN
            RETURN NULL;
        END IF;

        RETURN ROUND(v_normais * 100 / v_total, 1);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20010,
                'Metrica sem faixa de referencia cadastrada: ' || NVL(p_metric_code, '(nula)'));
    END fn_tempo_na_faixa;

    FUNCTION fn_rotulo_nivel (p_score IN NUMBER) RETURN VARCHAR2 DETERMINISTIC
    IS
    BEGIN
        RETURN CASE
                   WHEN p_score IS NULL THEN 'SEM DADOS'
                   WHEN p_score >= 90   THEN 'EXCELENTE'
                   WHEN p_score >= 75   THEN 'BOM'
                   WHEN p_score >= 60   THEN 'MODERADO'
                   WHEN p_score >= 40   THEN 'ATENCAO'
                   ELSE                      'CRITICO'
               END;
    END fn_rotulo_nivel;

    FUNCTION fn_formatar_leitura (p_reading_id IN NUMBER) RETURN VARCHAR2
    IS
        v_texto VARCHAR2(300);
    BEGIN
        -- A conversao de fuso (AT TIME ZONE) e uma expressao SQL.
        SELECT TO_CHAR(measured_at AT TIME ZONE 'America/Sao_Paulo', 'DD/MM/YYYY HH24:MI')
            || ' - FC '       || heart_rate || ' bpm'
            || '; SpO2 '      || TO_CHAR(spo2, 'FM990D0', c_decimal_br) || '%'
            || '; Glicemia '  || glucose_level || ' mg/dL'
            || '; PA '        || bp_systolic || '/' || bp_diastolic || ' mmHg'
            || '; Temp. '     || TO_CHAR(temperature, 'FM990D0', c_decimal_br) || ' C'
          INTO v_texto
          FROM vital_reading
         WHERE id = p_reading_id;

        RETURN v_texto;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END fn_formatar_leitura;

    FUNCTION fn_formatar_resumo_paciente (
        p_patient_id IN NUMBER,
        p_dias       IN NUMBER DEFAULT 30
    ) RETURN VARCHAR2
    IS
        v_nome      patient.name%TYPE;
        v_idade     patient.age%TYPE;
        v_condicoes VARCHAR2(400);
        v_ultima_id vital_reading.id%TYPE;
        v_score     NUMBER;
        v_tir       NUMBER;
        v_abertos   PLS_INTEGER;
        v_urgentes  PLS_INTEGER;
        v_texto     VARCHAR2(2000);
    BEGIN
        SELECT name, age
          INTO v_nome, v_idade
          FROM patient
         WHERE id = p_patient_id;

        SELECT LISTAGG(condition_name, ', ') WITHIN GROUP (ORDER BY condition_name)
          INTO v_condicoes
          FROM patient_condition
         WHERE patient_id = p_patient_id;

        -- Leitura mais recente sem NO_DATA_FOUND: MAX ... KEEP devolve NULL
        -- quando o paciente ainda nao tem leituras.
        SELECT MAX(id) KEEP (DENSE_RANK LAST ORDER BY measured_at)
          INTO v_ultima_id
          FROM vital_reading
         WHERE patient_id = p_patient_id;

        v_score := fn_calcular_score_saude(v_ultima_id);
        v_tir   := fn_tempo_na_faixa(p_patient_id, 'GLUCOSE', p_dias);

        SELECT COUNT(*),
               COUNT(CASE WHEN type = 'URGENT' THEN 1 END)
          INTO v_abertos, v_urgentes
          FROM health_alert
         WHERE patient_id   = p_patient_id
           AND acknowledged = 0;

        v_texto := v_nome || ', ' || v_idade || ' anos'
                || CASE WHEN v_condicoes IS NOT NULL THEN ' (' || v_condicoes || ')' END
                || ' | Score atual: '
                || CASE WHEN v_score IS NULL THEN 'sem leituras'
                        ELSE v_score || '/100 - ' || fn_rotulo_nivel(v_score) END
                || ' | Glicemia na faixa: '
                || CASE WHEN v_tir IS NULL THEN 'sem dados'
                        ELSE TO_CHAR(v_tir, 'FM990D0', c_decimal_br) || '% das leituras em ' || p_dias || ' dias' END
                || ' | Alertas abertos: ' || v_abertos
                || CASE WHEN v_urgentes > 0 THEN ' (' || v_urgentes || ' urgente' ||
                                                  CASE WHEN v_urgentes > 1 THEN 's' END || ')' END
                || CASE WHEN v_ultima_id IS NOT NULL
                        THEN ' | Ultima leitura: ' || fn_formatar_leitura(v_ultima_id) END;

        RETURN SUBSTR(v_texto, 1, 1000);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20004, 'Paciente ' || p_patient_id || ' nao encontrado.');
    END fn_formatar_resumo_paciente;
END pkg_clinico;
/
