-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 7
-- instalar.sql - instalacao completa do banco Oracle
--
-- SQL Developer: abra este arquivo e use "Executar Script" (F5).
-- SQL*Plus / SQLcl: @instalar.sql  (a partir desta pasta)
-- Pipeline CI/CD: executado pelo job "oracle" do GitHub Actions.
-- =============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
COLUMN object_type FORMAT A14
COLUMN object_name FORMAT A32
COLUMN status      FORMAT A8
COLUMN tabela      FORMAT A24
WHENEVER SQLERROR CONTINUE

PROMPT == 0/8 Removendo objetos anteriores
@@00_drop.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT == 1/8 Tabelas, constraints e indices
@@01_ddl_tabelas.sql

PROMPT == 2/8 PKG_AUDITORIA
@@02_pkg_auditoria.sql
SHOW ERRORS PACKAGE BODY pkg_auditoria

PROMPT == 3/8 PKG_CLINICO
@@03_pkg_clinico.sql
SHOW ERRORS PACKAGE BODY pkg_clinico

PROMPT == 4/8 PKG_MONITORAMENTO e PKG_RELATORIOS
@@04_pkg_monitoramento.sql
SHOW ERRORS PACKAGE BODY pkg_monitoramento
@@05_pkg_relatorios.sql
SHOW ERRORS PACKAGE BODY pkg_relatorios

PROMPT == 5/8 PKG_CONSULTAS (Dynamic SQL)
@@06_pkg_consultas.sql
SHOW ERRORS PACKAGE BODY pkg_consultas

PROMPT == 6/8 Triggers
@@07_triggers.sql

PROMPT == 7/8 Carga de dados simulados
@@08_carga_dados.sql

PROMPT == 8/8 Verificacao
SELECT object_type, object_name, status
  FROM user_objects
 WHERE object_type IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER')
 ORDER BY object_type, object_name;

-- Um package invalido nao gera erro no CREATE (apenas aviso): esta checagem
-- faz a instalacao falhar - e o pipeline quebrar - se algo nao compilou.
DECLARE
    v_invalidos PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_invalidos FROM user_objects WHERE status <> 'VALID';
    IF v_invalidos > 0 THEN
        RAISE_APPLICATION_ERROR(-20998, v_invalidos || ' objeto(s) invalido(s) no esquema.');
    END IF;
END;
/

SELECT 'patient' AS tabela, COUNT(*) AS linhas FROM patient
UNION ALL SELECT 'app_user', COUNT(*) FROM app_user
UNION ALL SELECT 'doctor', COUNT(*) FROM doctor
UNION ALL SELECT 'appointment', COUNT(*) FROM appointment
UNION ALL SELECT 'vital_reading', COUNT(*) FROM vital_reading
UNION ALL SELECT 'health_alert', COUNT(*) FROM health_alert
UNION ALL SELECT 'health_alert_audit', COUNT(*) FROM health_alert_audit
UNION ALL SELECT 'delivery_order', COUNT(*) FROM delivery_order
UNION ALL SELECT 'vital_reference_range', COUNT(*) FROM vital_reference_range
UNION ALL SELECT 'patient_report', COUNT(*) FROM patient_report
UNION ALL SELECT 'routine_execution_log', COUNT(*) FROM routine_execution_log;

WHENEVER SQLERROR CONTINUE
PROMPT == Instalacao concluida. Demonstracoes em 09_consultas_demonstracao.sql
PROMPT == Testes automatizados em 10_testes_automatizados.sql
