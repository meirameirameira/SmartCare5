-- =============================================================================
-- Smart HAS / SmartCare 5.0 - Fase 6
-- instalar.sql - instalacao completa do banco Oracle
--
-- SQL Developer: abra este arquivo e use "Executar Script" (F5).
-- SQL*Plus / SQLcl: @instalar.sql  (a partir desta pasta)
-- =============================================================================
SET DEFINE OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
COLUMN object_type FORMAT A12
COLUMN object_name FORMAT A32
COLUMN status      FORMAT A8
COLUMN tabela      FORMAT A24
WHENEVER SQLERROR CONTINUE

PROMPT == 0/5 Removendo objetos anteriores
@@00_drop.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT == 1/5 Tabelas, constraints e indices
@@01_ddl_tabelas.sql

PROMPT == 2/5 Functions
@@02_functions.sql

PROMPT == 3/5 Procedures
@@03_procedures.sql

PROMPT == 4/5 Carga de dados simulados
@@04_carga_dados.sql

PROMPT == 5/5 Verificacao
SELECT object_type, object_name, status
  FROM user_objects
 WHERE object_type IN ('FUNCTION', 'PROCEDURE')
 ORDER BY object_type, object_name;

SELECT 'patient' AS tabela, COUNT(*) AS linhas FROM patient
UNION ALL SELECT 'app_user', COUNT(*) FROM app_user
UNION ALL SELECT 'doctor', COUNT(*) FROM doctor
UNION ALL SELECT 'appointment', COUNT(*) FROM appointment
UNION ALL SELECT 'vital_reading', COUNT(*) FROM vital_reading
UNION ALL SELECT 'health_alert', COUNT(*) FROM health_alert
UNION ALL SELECT 'delivery_order', COUNT(*) FROM delivery_order
UNION ALL SELECT 'vital_reference_range', COUNT(*) FROM vital_reference_range
UNION ALL SELECT 'patient_report', COUNT(*) FROM patient_report
UNION ALL SELECT 'routine_execution_log', COUNT(*) FROM routine_execution_log;

WHENEVER SQLERROR CONTINUE
PROMPT == Instalacao concluida. Demonstracoes em 05_consultas_demonstracao.sql
