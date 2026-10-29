-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- 07_triggers.sql - triggers de auditoria e automacao
--
--   TRG_HEALTH_ALERT_RECONHECIMENTO  [automacao] data de reconhecimento
--   TRG_HEALTH_ALERT_AUDITORIA       [auditoria] trilha de cada alerta
--   TRG_DELIVERY_ORDER_STATUS        [automacao + regra] fluxo logistico
--   TRG_PATIENT_ATUALIZACAO          [automacao] carimbo de atualizacao
--
-- Por que no banco: a API (JPA), as procedures, o gateway IoT e um DBA no SQL
-- Developer escrevem nas mesmas tabelas. A trigger e o unico ponto pelo qual
-- toda escrita passa - a regra vale para qualquer origem, sem depender de cada
-- cliente lembrar dela.
-- Faixas de erro reservadas: -20020 a -20029.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- TRG_HEALTH_ALERT_RECONHECIMENTO  (automacao)
-- Proposito : manter ACKNOWLEDGED_AT coerente com ACKNOWLEDGED sem que o
--             chamador precise informar a data:
--               reconhecido sem data -> carimba SYSTIMESTAMP
--               reaberto (volta a 0) -> limpa a data
--             Roda antes do CHECK ck_alert_ack_date, entao um simples
--             "UPDATE health_alert SET acknowledged = 1" passa a ser valido.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_health_alert_reconhecimento
    BEFORE INSERT OR UPDATE OF acknowledged, acknowledged_at ON health_alert
    FOR EACH ROW
BEGIN
    IF :NEW.acknowledged = 1 AND :NEW.acknowledged_at IS NULL THEN
        :NEW.acknowledged_at := SYSTIMESTAMP;
    ELSIF :NEW.acknowledged = 0 THEN
        :NEW.acknowledged_at := NULL;
    END IF;
END trg_health_alert_reconhecimento;
/

-- -----------------------------------------------------------------------------
-- TRG_HEALTH_ALERT_AUDITORIA  (auditoria)
-- Proposito : gravar em HEALTH_ALERT_AUDIT cada evento do ciclo de vida de um
--             alerta - criacao, reconhecimento, reabertura, alteracao e
--             exclusao - com usuario do banco e modulo cliente (API via JDBC,
--             SQL Developer, SQL*Plus...). Responde perguntas como "quanto
--             tempo a equipe levou para reconhecer este alerta urgente?" e
--             "quem apagou este alerta?".
-- Observacao: a gravacao faz parte da mesma transacao do alerta - se a
--             operacao sofre ROLLBACK, a linha de auditoria tambem some, e a
--             trilha nunca registra um evento que nao aconteceu.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_health_alert_auditoria
    AFTER INSERT OR UPDATE OR DELETE ON health_alert
    FOR EACH ROW
DECLARE
    v_operacao health_alert_audit.operation%TYPE;
BEGIN
    v_operacao := CASE
                      WHEN INSERTING THEN 'CRIACAO'
                      WHEN DELETING  THEN 'EXCLUSAO'
                      WHEN :OLD.acknowledged = 0 AND :NEW.acknowledged = 1 THEN 'RECONHECIDO'
                      WHEN :OLD.acknowledged = 1 AND :NEW.acknowledged = 0 THEN 'REABERTO'
                      ELSE 'ALTERACAO'
                  END;

    INSERT INTO health_alert_audit (alert_id, patient_id, operation, alert_type, metric, title,
                                    old_acknowledged, new_acknowledged, client_module)
    VALUES (NVL(:NEW.id, :OLD.id),
            NVL(:NEW.patient_id, :OLD.patient_id),
            v_operacao,
            NVL(:NEW.type, :OLD.type),
            NVL(:NEW.metric, :OLD.metric),
            NVL(:NEW.title, :OLD.title),
            :OLD.acknowledged,
            :NEW.acknowledged,
            SUBSTR(SYS_CONTEXT('USERENV', 'MODULE'), 1, 64));
END trg_health_alert_auditoria;
/

-- -----------------------------------------------------------------------------
-- TRG_DELIVERY_ORDER_STATUS  (automacao + regra de negocio)
-- Proposito : aplicar no banco o mesmo fluxo logistico do DeliveryStatus
--             (Java) e automatizar os campos derivados:
--               - o status so avanca um passo por vez
--                 (CONFIRMED -> PREPARING -> IN_TRANSIT -> DELIVERED),
--                 podendo ser cancelado antes da entrega;
--               - DELIVERED e CANCELLED sao finais;
--               - pedido finalizado tem ETA zerado;
--               - UPDATED_AT e sempre carimbado.
-- Erros     : -20020 transicao de status invalida
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_delivery_order_status
    BEFORE UPDATE ON delivery_order
    FOR EACH ROW
DECLARE
    FUNCTION passo (p_status VARCHAR2) RETURN PLS_INTEGER IS
    BEGIN
        RETURN CASE p_status
                   WHEN 'CONFIRMED'  THEN 0
                   WHEN 'PREPARING'  THEN 1
                   WHEN 'IN_TRANSIT' THEN 2
                   WHEN 'DELIVERED'  THEN 3
               END;
    END passo;
BEGIN
    IF :NEW.status <> :OLD.status THEN
        IF :OLD.status IN ('DELIVERED', 'CANCELLED')
           OR (:NEW.status <> 'CANCELLED' AND passo(:NEW.status) <> passo(:OLD.status) + 1) THEN
            RAISE_APPLICATION_ERROR(-20020,
                'Transicao de status invalida no pedido ' || :OLD.order_code || ': '
                || :OLD.status || ' -> ' || :NEW.status || '.');
        END IF;
    END IF;

    IF :NEW.status IN ('DELIVERED', 'CANCELLED') THEN
        :NEW.eta_minutes := 0;
    END IF;

    :NEW.updated_at := SYSTIMESTAMP;
END trg_delivery_order_status;
/

-- -----------------------------------------------------------------------------
-- TRG_PATIENT_ATUALIZACAO  (automacao)
-- Proposito : carimbar UPDATED_AT do prontuario em qualquer alteracao, venha
--             ela da API ou de uma correcao manual no banco.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_patient_atualizacao
    BEFORE UPDATE ON patient
    FOR EACH ROW
BEGIN
    :NEW.updated_at := SYSTIMESTAMP;
END trg_patient_atualizacao;
/
