# Smart HAS · Banco Oracle e PL/SQL (Fase 7)

Camada de persistência Oracle do Smart HAS. A inteligência clínica fica no
banco, organizada em **5 packages**, protegida por **4 triggers** de auditoria e
automação, com **Dynamic SQL** para as consultas em tempo real da central de
monitoramento. A API Spring Boot chama os packages via JDBC.

## Instalação

Pré-requisito: Oracle 19c ou superior e um usuário com `CREATE TABLE`,
`CREATE PROCEDURE`, `CREATE TRIGGER` e `CREATE SEQUENCE`.

| Cenário | Script | O que faz |
|---|---|---|
| Banco novo / reinstalação | `instalar.sql` | Apaga tudo, cria tabelas, packages e triggers, carrega a massa simulada e falha se algum objeto ficar inválido |
| Banco que já tem dados | `deploy.sql` | Incremental e idempotente: cria só a estrutura nova, recompila packages e triggers e remove as rotinas avulsas da Fase 6 |
| Demonstração | `09_consultas_demonstracao.sql` | Uso prático de cada objeto (termina em `ROLLBACK`) |
| Testes | `10_testes_automatizados.sql` | 47 verificações; sai com erro se alguma falhar |

**SQL Developer:** abra o script e use *Executar Script* (F5).
**SQLcl / SQL\*Plus:** a partir desta pasta, `@instalar.sql`.

| Arquivo | Conteúdo |
|---|---|
| `00_drop.sql` | Remove packages, rotinas avulsas antigas e tabelas (ignora inexistentes) |
| `01_ddl_tabelas.sql` | 12 tabelas, PK/FK/UK/CHECK nomeadas, índices e comentários |
| `02_pkg_auditoria.sql` | `PKG_AUDITORIA` |
| `03_pkg_clinico.sql` | `PKG_CLINICO` |
| `04_pkg_monitoramento.sql` | `PKG_MONITORAMENTO` |
| `05_pkg_relatorios.sql` | `PKG_RELATORIOS` |
| `06_pkg_consultas.sql` | `PKG_CONSULTAS` (Dynamic SQL) |
| `07_triggers.sql` | 4 triggers |
| `08_carga_dados.sql` | 5 pacientes, 4 usuários, 3 médicos, 9 pedidos, ~900 leituras de sensores |
| `instalar.sql` / `deploy.sql` | Instalação completa / publicação incremental |

### Oracle local (Oracle AI Database Free)

Testado com o Oracle AI Database 26ai Free (Windows, `FREEPDB1`) e com a imagem
`gvenzl/oracle-free:23-slim` usada no pipeline. Crie o usuário como
administrador:

```sql
ALTER SESSION SET CONTAINER = FREEPDB1;
CREATE USER smarthas IDENTIFIED BY "SuaSenhaForte_26"
  DEFAULT TABLESPACE users QUOTA UNLIMITED ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE PROCEDURE, CREATE VIEW,
      CREATE SEQUENCE, CREATE TRIGGER TO smarthas;
```

Conecte como `smarthas` em `localhost:1521/FREEPDB1` e rode `instalar.sql`.

## Subindo a API sobre o Oracle

Crie `backend\oracle.local.bat` (ignorado pelo git):

```bat
@echo off
set "ORACLE_URL=jdbc:oracle:thin:@localhost:1521/FREEPDB1"
set "ORACLE_USER=smarthas"
set "ORACLE_PASSWORD=SuaSenhaForte_26"
```

e execute `backend\run-oracle.bat`. Com o perfil `oracle`, o Hibernate não
altera o esquema (`ddl-auto: none`) e o bean `PlsqlClinicalRoutines` passa a
atender o contrato `ClinicalRoutines`.

---

## Parte 1 · Objetos criados

### Por que packages

Na Fase 6 eram 10 functions e procedures avulsas. Agrupadas em packages:

- **Organização:** cada package é um módulo com responsabilidade única
  (auditoria, regra clínica, ingestão, relatórios, consultas). A *spec* é o
  contrato público; o *body* pode mudar sem invalidar quem chama.
- **Reuso:** rotinas privadas (`classificar`, `coluna_segura`,
  `validar_periodo`) e constantes (`c_normal`, `c_atencao`, `c_critico`,
  `c_sucesso`, `c_erro`) são compartilhadas sem ficarem expostas.
- **Overload:** `FN_CALCULAR_SCORE_SAUDE` tem duas versões — por id de leitura
  e pelos valores medidos — e a primeira reaproveita a segunda; a regra do
  score existe em um único lugar.
- **Estado de sessão:** `PKG_CONSULTAS` guarda o último SQL montado
  (`FN_ULTIMO_SQL`), recurso que só existe em package.
- **Governança:** um `GRANT EXECUTE ON pkg_x` concede o módulo inteiro; a
  dependência entre objetos é menor (recompilar um *body* não invalida os
  chamadores).

### PKG_AUDITORIA — governança

| Rotina | Finalidade | Valor agregado |
|---|---|---|
| `PRC_LOG_EXECUCAO(rotina, status, linhas, mensagem)` | Grava sucesso/falha em `ROUTINE_EXECUTION_LOG` com `PRAGMA AUTONOMOUS_TRANSACTION` | O registro de uma falha sobrevive ao `ROLLBACK` da operação; o log nunca derruba o negócio |
| `PRC_EXPURGAR_LOGS(dias, OUT removidos)` | Política de retenção das trilhas de log e de auditoria (mínimo 30 dias) | Controla o crescimento das tabelas de auditoria sem permitir apagar a trilha recente por engano (LGPD) |

### PKG_CLINICO — regras clínicas (functions puras, usáveis em `SELECT`)

| Rotina | Finalidade | Valor agregado |
|---|---|---|
| `FN_COLUNA_METRICA(metrica)` | Código da métrica → coluna de `VITAL_READING` | Lista branca única usada pelo Dynamic SQL contra SQL injection |
| `FN_CLASSIFICAR_SINAL(metrica, valor)` | NORMAL / ATTENTION / CRITICAL pela `VITAL_REFERENCE_RANGE` | Regras clínicas viram dado: ajustar um limite é um `UPDATE`, sem deploy |
| `FN_CALCULAR_SCORE_SAUDE(leitura)` | Score 0–100 de uma leitura gravada | Mesmo cálculo do Java e do Flutter (testes de paridade) |
| `FN_CALCULAR_SCORE_SAUDE(fc, spo2, glic, sis, dia, temp)` | Score de uma leitura ainda não gravada | Simulação e validação pelo gateway antes de persistir |
| `FN_TEMPO_NA_FAIXA(paciente, metrica, dias)` | % de leituras na faixa normal (Time in Range) | Indicador recomendado para acompanhamento de diabéticos |
| `FN_ROTULO_NIVEL(score)` | EXCELENTE … CRITICO | Mesmo rótulo no app, no painel e no relatório |
| `FN_FORMATAR_LEITURA(leitura)` | Leitura em uma linha, padrão brasileiro | Formatação pronta para telas e relatórios |
| `FN_FORMATAR_RESUMO_PACIENTE(paciente, dias)` | Resumo clínico textual | Texto gravado em `PATIENT_REPORT` e exibido no app |

### PKG_MONITORAMENTO — ingestão e alertas

| Rotina | Finalidade | Valor agregado |
|---|---|---|
| `PRC_REGISTRAR_ALERTAS_LEITURA(leitura, OUT qtd)` | Abre alerta URGENT/WARNING para cada sinal fora da faixa, sem duplicar alertas abertos | **Chamada pela API a cada leitura**; alertas iguais aos do motor Java |
| `PRC_REGISTRAR_LEITURA(...)` | Ingestão direta do gateway IoT, com validação de paciente, data e limites fisiológicos | Leitura e alertas na mesma transação |
| `PRC_RECONHECER_ALERTA(alerta)` | Marca o alerta como tratado | Data e auditoria preenchidas pelas triggers |

### PKG_RELATORIOS — consolidação

| Rotina | Finalidade | Valor agregado |
|---|---|---|
| `PRC_CONSOLIDAR_RELATORIO(paciente, dias, OUT qtd)` | Relatório clínico e de consumo de medicamentos em `PATIENT_REPORT` (MERGE), um paciente ou todos | **Chamada pelo app e pelo painel**; `SAVEPOINT` por paciente — uma falha não interrompe o lote |

### PKG_CONSULTAS — Dynamic SQL para consultas em tempo real

A central de monitoramento combina filtros livremente e troca ordenação e
agrupamento a cada clique. Com SQL estático seria preciso um comando por
combinação, ou um único `WHERE (:x IS NULL OR ...)` que impede o otimizador de
usar os índices. Com Dynamic SQL, **só os filtros informados entram no texto**
e cada combinação ganha o próprio plano de execução.

| Rotina | Técnica | Flexibilidade |
|---|---|---|
| `FN_BUSCAR_LEITURAS(paciente, metrica, valor_min, valor_max, somente_alteradas, dias, ordenar_por, direcao, limite)` | `DBMS_SQL` com *bind* condicional + `DBMS_SQL.TO_REFCURSOR` | Todos os filtros opcionais; ordenação por DATA, VALOR, SCORE ou PACIENTE; devolve `SYS_REFCURSOR` |
| `FN_INDICADOR(metrica, agregacao, paciente, dias)` | `EXECUTE IMMEDIATE ... INTO ... USING` | Agregação (AVG, MIN, MAX, STDDEV, MEDIAN, COUNT) e métrica escolhidas em tempo de execução |
| `PRC_PAINEL_TEMPO_REAL(agrupar_por, dias, OUT cursor)` | `OPEN cursor FOR string USING` | Painel agrupado por PACIENTE, DIA ou HORA |
| `FN_ULTIMO_SQL` | Estado de sessão do package | Mostra o comando montado (depuração e demonstração) |

Exemplo — glicemias fora da faixa na última semana, da maior para a menor:

```sql
VARIABLE rc REFCURSOR
EXEC :rc := pkg_consultas.fn_buscar_leituras(p_metric_code => 'GLUCOSE', p_somente_alteradas => 'S', p_dias => 7, p_ordenar_por => 'VALOR')
PRINT rc
SELECT pkg_consultas.fn_ultimo_sql FROM dual;
```

SQL montado (repare que não há filtro de paciente nem de valor):

```sql
SELECT ... FROM vital_reading v JOIN patient p ON p.id = v.patient_id
 WHERE v.measured_at >= SYSTIMESTAMP - NUMTODSINTERVAL(:dias, 'DAY')
   AND EXISTS (SELECT 1 FROM vital_reference_range r WHERE r.metric_code = :metrica
               AND v.GLUCOSE_LEVEL NOT BETWEEN r.normal_min AND r.normal_max)
 ORDER BY v.GLUCOSE_LEVEL DESC NULLS LAST, v.id FETCH FIRST :limite ROWS ONLY
```

**Proteção contra SQL injection:** valores do usuário entram sempre como
*bind variables*; identificadores (coluna, agregação, ordenação) vêm de listas
brancas e passam por `DBMS_ASSERT.SIMPLE_SQL_NAME`. Os testes automatizados
tentam injetar código em cada parâmetro e conferem a rejeição.

### Triggers

| Trigger | Tipo | Finalidade | Valor agregado |
|---|---|---|---|
| `TRG_HEALTH_ALERT_RECONHECIMENTO` | BEFORE INSERT/UPDATE, linha | Carimba `ACKNOWLEDGED_AT` ao reconhecer e limpa ao reabrir | Um simples `UPDATE ... SET acknowledged = 1` já é válido, venha de onde vier |
| `TRG_HEALTH_ALERT_AUDITORIA` | AFTER INSERT/UPDATE/DELETE, linha | Grava em `HEALTH_ALERT_AUDIT` criação, reconhecimento, reabertura, alteração e exclusão, com usuário e módulo cliente | Responde "quem apagou este alerta?" e "quanto tempo a equipe levou para reconhecer?"; a trilha sobrevive à exclusão do alerta |
| `TRG_DELIVERY_ORDER_STATUS` | BEFORE UPDATE, linha | Aplica o fluxo logístico (um passo por vez; DELIVERED/CANCELLED finais), zera o ETA de pedidos finalizados e carimba `UPDATED_AT` | A mesma regra do `DeliveryStatus` (Java) vale para qualquer origem, inclusive correções manuais no banco |
| `TRG_PATIENT_ATUALIZACAO` | BEFORE UPDATE, linha | Carimba `UPDATED_AT` do prontuário | Data de atualização sempre confiável |

Tabela nova: **`HEALTH_ALERT_AUDIT`** — preenchida apenas pela trigger, sem FK
para `HEALTH_ALERT` de propósito (a trilha precisa sobreviver à exclusão).

## Integração com o back-end

```
App Flutter / Painel Angular
   └─ REST  POST /api/v1/patients/{id}/vitals        GET /api/v1/patients/{id}/report
            POST /api/v1/reports/consolidation
        └─ Spring (VitalService / ReportService, @Transactional)
            └─ PlsqlClinicalRoutines → JdbcTemplate → CallableStatement
                └─ {call pkg_monitoramento.prc_registrar_alertas_leitura(?, ?)}
                   {call pkg_relatorios.prc_consolidar_relatorio(?, ?, ?)}
                        └─ INSERT em health_alert → TRG_HEALTH_ALERT_AUDITORIA
```

## Códigos de erro

`RAISE_APPLICATION_ERROR` é traduzido para HTTP por `OracleErrorTranslator`:

| Código | Situação | Origem | HTTP |
|---|---|---|---|
| -20001 | leitura inexistente | PKG_MONITORAMENTO | 404 |
| -20002 | alerta inexistente | PKG_MONITORAMENTO | 404 |
| -20003 | período fora de 1–365 dias | PKG_RELATORIOS | 422 |
| -20004 | paciente inexistente | vários | 404 |
| -20005 | falha ao consolidar o paciente | PKG_RELATORIOS | 422 |
| -20006 | medição com data futura | PKG_MONITORAMENTO | 422 |
| -20007 | valor fora do limite fisiológico | PKG_MONITORAMENTO | 422 |
| -20008 | retenção de log menor que 30 dias | PKG_AUDITORIA | 422 |
| -20010 a -20012 | métrica, cálculo ou período inválidos | PKG_CLINICO | 422 |
| -20013 a -20016 | período/limite, ordenação, filtro sem métrica, agregação inválidos | PKG_CONSULTAS | 422 |
| -20020 | transição de status de pedido inválida | TRG_DELIVERY_ORDER_STATUS | 422 |

## Testes automatizados

`10_testes_automatizados.sql` roda no pipeline CI/CD a cada push e verifica:
objetos válidos, classificação e score (incluindo o overload), ingestão e
deduplicação de alertas, as quatro triggers (carimbos, auditoria, fluxo
logístico), o Dynamic SQL (resultado igual ao de uma consulta estática
equivalente, só os filtros informados no texto, tentativas de injeção
rejeitadas) e todos os códigos de erro. Qualquer falha encerra o SQL\*Plus com
erro e quebra o pipeline.
