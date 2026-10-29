-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 6
-- 04_carga_dados.sql - importacao de dados simulados
--
--   1. Faixas clinicas de referencia (parametros das functions)
--   2. Pacientes, condicoes, usuarios, profissionais, consultas e pedidos
--   3. Historico de 30 dias de leituras de sensores (1 leitura a cada 4 horas
--      por paciente), gerado por PL/SQL com semente fixa - todo ambiente
--      recebe exatamente os mesmos dados
--   4. Leituras alteradas registradas pela procedure de ingestao, para que os
--      alertas nascam do proprio motor de regras do banco
--   5. Relatorios consolidados de 7 e 30 dias
--
-- Credenciais de demonstracao (senhas gravadas apenas como hash BCrypt):
--   admin@smarthas.com / admin123          (ADMIN)
--   enfermagem@smarthas.com / enfermagem123 (PROFESSIONAL)
--   felipe@smarthas.com / paciente123      (PATIENT)
--   joao@smarthas.com / paciente123        (PATIENT)
-- =============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED

-- -----------------------------------------------------------------------------
-- 1. Faixas de referencia - os mesmos valores do HealthScoreCalculator (Java)
--    e do HealthScoreEngine (Flutter). O teste ReferenceRangeParityTest do
--    back-end le este arquivo e falha se as tres camadas divergirem.
-- -----------------------------------------------------------------------------
INSERT INTO vital_reference_range VALUES ('HEART_RATE',  'Freq. cardiaca',     'bpm',   60,   100,   50,   110,  18, 1);
INSERT INTO vital_reference_range VALUES ('SPO2',        'SpO2',               '%',     95,   100,   90,   100,  22, 2);
INSERT INTO vital_reference_range VALUES ('GLUCOSE',     'Glicemia',           'mg/dL', 70,   120,   60,   180,  22, 3);
INSERT INTO vital_reference_range VALUES ('SYSTOLIC',    'Pressao sistolica',  'mmHg',  90,   129,   85,   139,  18, 4);
INSERT INTO vital_reference_range VALUES ('DIASTOLIC',   'Pressao diastolica', 'mmHg',  60,   84,    55,   89,   10, 5);
INSERT INTO vital_reference_range VALUES ('TEMPERATURE', 'Temperatura',        'C',     35.5, 37.5,  35.0, 38.5, 10, 6);

-- -----------------------------------------------------------------------------
-- 2. Cadastros
-- -----------------------------------------------------------------------------
DECLARE
    v_felipe  patient.id%TYPE;
    v_joao    patient.id%TYPE;
    v_maria   patient.id%TYPE;
    v_ana     patient.id%TYPE;
    v_carlos  patient.id%TYPE;
    v_ricardo doctor.id%TYPE;
    v_lima    doctor.id%TYPE;
    v_paulo   doctor.id%TYPE;

BEGIN
    INSERT INTO patient (name, age, wearable_connected) VALUES ('Felipe Meira', 22, 1)   RETURNING id INTO v_felipe;
    INSERT INTO patient (name, age, wearable_connected) VALUES ('Joao Silva', 68, 1)     RETURNING id INTO v_joao;
    INSERT INTO patient (name, age, wearable_connected) VALUES ('Maria Oliveira', 74, 1) RETURNING id INTO v_maria;
    INSERT INTO patient (name, age, wearable_connected) VALUES ('Ana Costa', 59, 1)      RETURNING id INTO v_ana;
    INSERT INTO patient (name, age, wearable_connected) VALUES ('Carlos Pereira', 81, 0) RETURNING id INTO v_carlos;

    INSERT INTO patient_condition VALUES (v_felipe, 'Hipertensao leve');
    INSERT INTO patient_condition VALUES (v_felipe, 'Diabetes tipo 2');
    INSERT INTO patient_condition VALUES (v_joao,   'Diabetes tipo 2');
    INSERT INTO patient_condition VALUES (v_maria,  'Insuficiencia cardiaca');
    INSERT INTO patient_condition VALUES (v_ana,    'DPOC');
    INSERT INTO patient_condition VALUES (v_carlos, 'Hipertensao');
    INSERT INTO patient_condition VALUES (v_carlos, 'Fibrilacao atrial');

    INSERT INTO app_user (email, password_hash, name, role)
    VALUES ('admin@smarthas.com', '$2a$10$8S09J0kExeR4vkoHvzovfO0Rp0NxZmtGQtUMKRs0Tzr26TZ16jCfK', 'Administracao Smart HAS', 'ADMIN');
    INSERT INTO app_user (email, password_hash, name, role)
    VALUES ('enfermagem@smarthas.com', '$2a$10$3KzW2LcDWWsIuKRUa.eY5u04GVCrBmdBbVNnVeHodlK1JqS5nDNLC', 'Enf. Carla Souza', 'PROFESSIONAL');
    INSERT INTO app_user (email, password_hash, name, role, patient_id)
    VALUES ('felipe@smarthas.com', '$2a$10$yQmVZcQd9DifaKmp9UjJyO/UkRhcQtoLjOvYq9sWWlH7a9cMPNTia', 'Felipe Meira', 'PATIENT', v_felipe);
    INSERT INTO app_user (email, password_hash, name, role, patient_id)
    VALUES ('joao@smarthas.com', '$2a$10$kPJdn8zzHQ6ofEo.4cxs/./jG1e/VTqTF/VUvamOQrI.oJ8v5FWg6', 'Joao Silva', 'PATIENT', v_joao);

    INSERT INTO doctor (name, specialty, crm, available) VALUES ('Dr. Ricardo Alves', 'Endocrinologia', 'CRM/SP 87432', 1) RETURNING id INTO v_ricardo;
    INSERT INTO doctor (name, specialty, crm, available) VALUES ('Dra. Ana Lima', 'Clinica Geral', 'CRM/SP 54210', 1)     RETURNING id INTO v_lima;
    INSERT INTO doctor (name, specialty, crm, available) VALUES ('Dr. Paulo Neto', 'Cardiologia', 'CRM/SP 33091', 0)      RETURNING id INTO v_paulo;

    INSERT INTO appointment (patient_id, doctor_id, scheduled_at, telemedicine, status, notes)
    VALUES (v_felipe, v_ricardo, SYSTIMESTAMP + NUMTODSINTERVAL(6, 'HOUR'), 1, 'SCHEDULED', 'Revisao trimestral de glicemia');
    INSERT INTO appointment (patient_id, doctor_id, scheduled_at, telemedicine, status, notes)
    VALUES (v_joao, v_lima, SYSTIMESTAMP + NUMTODSINTERVAL(1, 'DAY'), 1, 'CONFIRMED', 'Ajuste da dose de insulina');
    INSERT INTO appointment (patient_id, doctor_id, scheduled_at, telemedicine, status, notes)
    VALUES (v_carlos, v_paulo, SYSTIMESTAMP - NUMTODSINTERVAL(72, 'HOUR'), 0, 'COMPLETED', 'Controle de anticoagulacao');

    -- Pedidos da camada AI Logistics (consumo de medicamentos).
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, proactive_message, created_at, updated_at)
    VALUES (v_felipe, 'SC-2026-0412', 'Metformina 500mg (60cp) + Losartana 50mg (30cp)', 'Farmacia Leroy Health', 'IN_TRANSIT', 3.2, 28,
            'IA detectou transito na Av. Paulista - rota alternativa ativa. ETA mantido.', SYSTIMESTAMP - NUMTODSINTERVAL(2, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(1, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, proactive_message, created_at, updated_at)
    VALUES (v_felipe, 'SC-2026-0371', 'Metformina 500mg (60cp)', 'Farmacia Leroy Health', 'DELIVERED', 3.0, 0,
            'Entrega concluida e confirmada pelo paciente.', SYSTIMESTAMP - NUMTODSINTERVAL(20 * 24, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(20 * 24 - 1, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, proactive_message, created_at, updated_at)
    VALUES (v_joao, 'SC-2026-0388', 'Insulina NPH (2 frascos)', 'Drogaria Central', 'DELIVERED', 1.8, 0,
            'Entrega concluida e confirmada pelo paciente.', SYSTIMESTAMP - NUMTODSINTERVAL(12 * 24, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(12 * 24 - 2, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, created_at, updated_at)
    VALUES (v_joao, 'SC-2026-0402', 'Tiras reagentes de glicemia (100un)', 'Drogaria Central', 'CONFIRMED', 1.8, 55, SYSTIMESTAMP - NUMTODSINTERVAL(3, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(3, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, proactive_message, created_at, updated_at)
    VALUES (v_maria, 'SC-2026-0395', 'Furosemida 40mg (30cp) + Carvedilol 6,25mg (60cp)', 'Farmacia Bem Estar', 'DELIVERED', 4.6, 0,
            'Entrega concluida e confirmada pelo paciente.', SYSTIMESTAMP - NUMTODSINTERVAL(9 * 24, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(9 * 24 - 2, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, created_at, updated_at)
    VALUES (v_maria, 'SC-2026-0409', 'Espironolactona 25mg (30cp)', 'Farmacia Bem Estar', 'PREPARING', 4.6, 70, SYSTIMESTAMP - NUMTODSINTERVAL(5, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(4, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, proactive_message, created_at, updated_at)
    VALUES (v_ana, 'SC-2026-0399', 'Budesonida + Formoterol (inalador)', 'Drogaria Central', 'DELIVERED', 2.4, 0,
            'Entrega concluida e confirmada pelo paciente.', SYSTIMESTAMP - NUMTODSINTERVAL(6 * 24, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(6 * 24 - 1, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, proactive_message, created_at, updated_at)
    VALUES (v_carlos, 'SC-2026-0390', 'Varfarina 5mg (30cp)', 'Farmacia Popular Centro', 'CANCELLED', 6.1, 0,
            'Pedido cancelado: receita vencida. Equipe notificada.', SYSTIMESTAMP - NUMTODSINTERVAL(15 * 24, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(15 * 24 - 3, 'HOUR'));
    INSERT INTO delivery_order (patient_id, order_code, description, pharmacy_name, status, distance_km, eta_minutes, proactive_message, created_at, updated_at)
    VALUES (v_carlos, 'SC-2026-0410', 'Varfarina 5mg (30cp) + Anlodipino 5mg (30cp)', 'Farmacia Popular Centro', 'IN_TRANSIT', 6.1, 35,
            'Entregador a 2 paradas do destino.', SYSTIMESTAMP - NUMTODSINTERVAL(4, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(1, 'HOUR'));

    -- Um alerta antigo ja tratado, para o historico nao comecar vazio.
    INSERT INTO health_alert (patient_id, type, title, description, metric, acknowledged, created_at, acknowledged_at)
    VALUES (v_felipe, 'INFO', 'Lembrete de hidratacao', 'Temperatura ambiente elevada: aumente a ingestao de agua.',
            NULL, 1, SYSTIMESTAMP - NUMTODSINTERVAL(48, 'HOUR'), SYSTIMESTAMP - NUMTODSINTERVAL(47, 'HOUR'));

    DBMS_OUTPUT.PUT_LINE('Cadastros importados.');
END;
/

-- -----------------------------------------------------------------------------
-- 3. Historico de leituras dos sensores (30 dias x 6 leituras/dia x 5 pacientes)
--    Passeio aleatorio com retorno a linha de base de cada perfil clinico.
--    DBMS_RANDOM.SEED com o nome do paciente torna a serie reprodutivel.
-- -----------------------------------------------------------------------------
DECLARE
    c_leituras CONSTANT PLS_INTEGER := 180;   -- 30 dias, uma a cada 4 horas

    TYPE t_perfil IS RECORD (
        fc NUMBER, spo2 NUMBER, glic NUMBER, sis NUMBER, dia NUMBER, temp NUMBER
    );

    CURSOR c_pacientes IS
        SELECT id, name FROM patient ORDER BY id;

    v_base  t_perfil;
    v_atual t_perfil;
    v_total PLS_INTEGER := 0;

    -- Linha de base coerente com as condicoes clinicas de cada paciente.
    FUNCTION perfil (p_nome VARCHAR2) RETURN t_perfil IS
        r t_perfil;
    BEGIN
        CASE p_nome
            WHEN 'Joao Silva'     THEN r.fc := 76; r.spo2 := 96.5; r.glic := 128; r.sis := 128; r.dia := 82; r.temp := 36.5;
            WHEN 'Maria Oliveira' THEN r.fc := 88; r.spo2 := 94.8; r.glic := 110; r.sis := 124; r.dia := 79; r.temp := 36.4;
            WHEN 'Ana Costa'      THEN r.fc := 82; r.spo2 := 94.2; r.glic := 98;  r.sis := 121; r.dia := 77; r.temp := 36.7;
            WHEN 'Carlos Pereira' THEN r.fc := 90; r.spo2 := 96.0; r.glic := 112; r.sis := 136; r.dia := 86; r.temp := 36.5;
            ELSE                       r.fc := 72; r.spo2 := 98.5; r.glic := 104; r.sis := 118; r.dia := 78; r.temp := 36.6;
        END CASE;
        RETURN r;
    END perfil;

    -- Proximo valor: ruido uniforme +-amplitude e 20% de retorno a base.
    FUNCTION passo (p_valor NUMBER, p_base NUMBER, p_amplitude NUMBER,
                    p_min NUMBER, p_max NUMBER, p_casas PLS_INTEGER) RETURN NUMBER IS
    BEGIN
        RETURN ROUND(LEAST(p_max, GREATEST(p_min,
                   p_valor + DBMS_RANDOM.VALUE(-p_amplitude, p_amplitude) + (p_base - p_valor) * 0.2)), p_casas);
    END passo;
BEGIN
    FOR p IN c_pacientes LOOP
        DBMS_RANDOM.SEED(p.name);
        v_base  := perfil(p.name);
        v_atual := v_base;

        FOR i IN REVERSE 1 .. c_leituras LOOP
            v_atual.fc   := passo(v_atual.fc,   v_base.fc,   5,   48,   125,  0);
            v_atual.spo2 := passo(v_atual.spo2, v_base.spo2, 0.8, 89,   100,  1);
            v_atual.glic := passo(v_atual.glic, v_base.glic, 12,  65,   210,  0);
            v_atual.sis  := passo(v_atual.sis,  v_base.sis,  5,   95,   160,  0);
            v_atual.dia  := passo(v_atual.dia,  v_base.dia,  4,   58,   98,   0);
            v_atual.temp := passo(v_atual.temp, v_base.temp, 0.2, 35.6, 37.9, 1);

            INSERT INTO vital_reading (patient_id, heart_rate, spo2, glucose_level,
                                       bp_systolic, bp_diastolic, temperature, measured_at)
            VALUES (p.id, v_atual.fc, v_atual.spo2, v_atual.glic,
                    v_atual.sis, v_atual.dia, v_atual.temp,
                    SYSTIMESTAMP - NUMTODSINTERVAL(i * 4, 'HOUR'));

            v_total := v_total + 1;
        END LOOP;
    END LOOP;

    DBMS_RANDOM.TERMINATE;
    DBMS_OUTPUT.PUT_LINE(v_total || ' leituras de sensores importadas.');
END;
/

-- -----------------------------------------------------------------------------
-- 4. Leituras alteradas pela porta de ingestao do gateway IoT: os alertas sao
--    gerados pela PRC_REGISTRAR_ALERTAS_LEITURA, nunca escritos a mao.
-- -----------------------------------------------------------------------------
DECLARE
    v_leitura NUMBER;
    v_alertas NUMBER;
    v_total   PLS_INTEGER := 0;

    FUNCTION paciente (p_nome VARCHAR2) RETURN NUMBER IS
        v_id patient.id%TYPE;
    BEGIN
        SELECT id INTO v_id FROM patient WHERE name = p_nome;
        RETURN v_id;
    END paciente;
BEGIN
    -- Joao: taquicardia e glicemia alta (mesmo quadro da carga Java).
    prc_registrar_leitura(paciente('Joao Silva'), 112, 93.4, 168, 138, 88, 37.4,
                          SYSTIMESTAMP - NUMTODSINTERVAL(35, 'MINUTE'), v_leitura, v_alertas);
    v_total := v_total + v_alertas;

    -- Maria: dessaturacao critica.
    prc_registrar_leitura(paciente('Maria Oliveira'), 98, 88.5, 118, 128, 82, 36.9,
                          SYSTIMESTAMP - NUMTODSINTERVAL(20, 'MINUTE'), v_leitura, v_alertas);
    v_total := v_total + v_alertas;

    -- Carlos: crise hipertensiva.
    prc_registrar_leitura(paciente('Carlos Pereira'), 94, 95.8, 121, 162, 99, 36.6,
                          SYSTIMESTAMP - NUMTODSINTERVAL(15, 'MINUTE'), v_leitura, v_alertas);
    v_total := v_total + v_alertas;

    -- Demais pacientes: avalia a leitura mais recente do historico.
    FOR p IN (SELECT id FROM patient WHERE name IN ('Felipe Meira', 'Ana Costa')) LOOP
        SELECT MAX(id) KEEP (DENSE_RANK LAST ORDER BY measured_at)
          INTO v_leitura
          FROM vital_reading
         WHERE patient_id = p.id;

        prc_registrar_alertas_leitura(v_leitura, v_alertas);
        v_total := v_total + v_alertas;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(v_total || ' alertas gerados pelo motor de regras PL/SQL.');
END;
/

-- -----------------------------------------------------------------------------
-- 5. Relatorios consolidados (7 e 30 dias) para todos os pacientes
-- -----------------------------------------------------------------------------
DECLARE
    v_processados NUMBER;
BEGIN
    prc_consolidar_relatorio(NULL, 7, v_processados);
    DBMS_OUTPUT.PUT_LINE('Relatorio de 7 dias: ' || v_processados || ' pacientes.');

    prc_consolidar_relatorio(NULL, 30, v_processados);
    DBMS_OUTPUT.PUT_LINE('Relatorio de 30 dias: ' || v_processados || ' pacientes.');
END;
/

COMMIT;
