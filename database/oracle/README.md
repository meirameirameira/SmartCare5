# Smart HAS · Banco Oracle e rotinas PL/SQL (Fase 6)

Camada de persistência Oracle do Smart HAS, com a inteligência clínica escrita
em PL/SQL e chamada pela API Spring Boot via JDBC.

## Instalação

Pré-requisito: Oracle 19c ou superior (por exemplo `oracle.fiap.com.br:1521:ORCL`)
e um usuário com permissão de `CREATE TABLE` e `CREATE PROCEDURE`.

**SQL Developer:** abra `instalar.sql` e use *Executar Script* (F5).
**SQLcl / SQL\*Plus:** a partir desta pasta, `@instalar.sql`.

O instalador remove objetos anteriores, cria tabelas, functions e procedures,
importa a carga simulada e lista o status dos objetos e a contagem de linhas.
Depois, rode `05_consultas_demonstracao.sql` para ver o uso prático das rotinas.

| Arquivo | Conteúdo |
|---|---|
| `00_drop.sql` | Remove os objetos (ignora os inexistentes) |
| `01_ddl_tabelas.sql` | 11 tabelas, PK/FK/UK/CHECK nomeadas, índices e comentários |
| `02_functions.sql` | 6 functions |
| `03_procedures.sql` | 4 procedures |
| `04_carga_dados.sql` | 5 pacientes, 4 usuários, 3 médicos, 9 pedidos, ~900 leituras de sensores |
| `05_consultas_demonstracao.sql` | 8 consultas e 3 blocos anônimos de demonstração |
| `instalar.sql` | Executa tudo em ordem |

### Oracle local (Oracle AI Database Free)

Testado com o Oracle AI Database 26ai Free para Windows, banco plugável
`FREEPDB1`. Após instalar, crie o usuário da aplicação conectado como
administrador (no Windows, `sqlplus / as sysdba` funciona sem senha para o
usuário que fez a instalação):

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER smarthas IDENTIFIED BY "SuaSenhaForte_26"
  DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE PROCEDURE, CREATE VIEW, CREATE SEQUENCE TO smarthas;
```

Conecte como `smarthas` em `localhost:1521/FREEPDB1` e rode `instalar.sql`.

## Subindo a API sobre o Oracle

Crie `backend\oracle.local.bat` (ignorado pelo git) com as credenciais:

```bat
@echo off
set "ORACLE_URL=jdbc:oracle:thin:@localhost:1521/FREEPDB1"
set "ORACLE_USER=smarthas"
set "ORACLE_PASSWORD=SuaSenhaForte_26"
```

e execute `backend\run-oracle.bat`. Para o Oracle da FIAP, defina as mesmas
variáveis com `jdbc:oracle:thin:@oracle.fiap.com.br:1521:ORCL`.

Com o perfil `oracle`, o Hibernate não altera o esquema (`ddl-auto: none`) e
o bean `PlsqlClinicalRoutines` passa a atender o contrato `ClinicalRoutines`.

## Rotinas

| Rotina | Tipo | Uso |
|---|---|---|
| `FN_CLASSIFICAR_SINAL(metrica, valor)` | function | NORMAL / ATTENTION / CRITICAL pela `VITAL_REFERENCE_RANGE` |
| `FN_CALCULAR_SCORE_SAUDE(leitura)` | function (indicador) | Score 0–100 da leitura |
| `FN_TEMPO_NA_FAIXA(paciente, metrica, dias)` | function (indicador) | % de leituras na faixa normal (Time in Range) |
| `FN_ROTULO_NIVEL(score)` | function | EXCELENTE … CRITICO |
| `FN_FORMATAR_LEITURA(leitura)` | function (dado formatado) | Leitura em uma linha, padrão brasileiro |
| `FN_FORMATAR_RESUMO_PACIENTE(paciente, dias)` | function (dado formatado) | Resumo clínico textual |
| `PRC_LOG_EXECUCAO` | procedure | Auditoria em transação autônoma |
| `PRC_REGISTRAR_ALERTAS_LEITURA(leitura, OUT qtd)` | procedure | Abre alertas para sinais fora da faixa — **chamada pela API a cada leitura** |
| `PRC_REGISTRAR_LEITURA(...)` | procedure | Ingestão direta do gateway IoT |
| `PRC_CONSOLIDAR_RELATORIO(paciente, dias, OUT qtd)` | procedure | Relatório clínico e de consumo em `PATIENT_REPORT` — **chamada pelo app e pelo painel** |

### Integração com o back-end

```
App Flutter / Painel Angular
   └─ REST  POST /api/v1/patients/{id}/vitals        GET /api/v1/patients/{id}/report
            POST /api/v1/reports/consolidation
        └─ Spring (VitalService / ReportService, @Transactional)
            └─ PlsqlClinicalRoutines → JdbcTemplate → CallableStatement
                └─ {call prc_registrar_alertas_leitura(?, ?)}
                   {call prc_consolidar_relatorio(?, ?, ?)}
```

Erros `RAISE_APPLICATION_ERROR` são traduzidos por `OracleErrorTranslator`:

| Código | Situação | HTTP |
|---|---|---|
| -20001 | leitura inexistente | 404 |
| -20003 | período fora de 1–365 dias | 422 |
| -20004 | paciente inexistente | 404 |
| -20005 | falha ao consolidar o paciente | 422 |
| -20006 | medição com data futura | 422 |
| -20007 | valor fora do limite fisiológico | 422 |
| -20010 a -20012 | parâmetros inválidos nas functions | 422 |
