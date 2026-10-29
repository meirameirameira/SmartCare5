# Smart HAS · Pipeline CI/CD (Fase 7 – Parte 2)

Pipeline em **GitHub Actions** — [`.github/workflows/ci-cd.yml`](../.github/workflows/ci-cd.yml).
Roda a cada *push* e *pull request* na `main` e pode ser disparado manualmente
(aba *Actions* → *CI/CD Smart HAS* → *Run workflow*).

```
                 ┌──────────────┐
 push / PR ──┬──▶│   backend    │── jar ──┐
             │   └──────────────┘         ▼
             │   ┌──────────────┐   ┌──────────────┐
             ├──▶│     web      │   │    oracle    │  Oracle Free em container
             │   └──────────────┘   └──────────────┘
             │   ┌──────────────┐          │
             └──▶│    mobile    │          │
                 └──────────────┘          │
                        └────────┬─────────┘
                                 ▼  (somente main)
                          ┌──────────────┐
                          │    deploy    │  GHCR + Oracle de destino + API
                          └──────────────┘
```

## Jobs

### 1. `backend` — build e testes automatizados

- JDK 21 (Temurin) com cache do Gradle.
- `./gradlew build`: compila, roda os **35 testes JUnit** (integração da API,
  ponte JDBC com os packages, paridade de faixas clínicas) e gera o jar
  `smarthas-api.jar`.
- **JaCoCo** gera o relatório de cobertura; o percentual de linhas vai para o
  resumo da execução.
- O relatório JUnit é publicado como *check* no commit/PR
  (`mikepenz/action-junit-report`), com a lista de testes.

### 2. `web` — painel Angular

`npm ci`, **19 testes Vitest** e build de produção. O `dist/` fica disponível
como artefato.

### 3. `mobile` — app Flutter

`flutter analyze` e **93 testes** (incluindo o teste de paridade que lê a
carga Oracle).

### 4. `oracle` — integração com o banco Oracle

Sobe o **Oracle Database Free 23** como *service container*
(`gvenzl/oracle-free:23-slim`) e, em sequência:

| Passo | O que comprova | Log |
|---|---|---|
| Cria o usuário `smarthas` com os privilégios mínimos | — | `00_usuario.log` |
| `instalar.sql` (tabelas, 5 packages, 4 triggers, carga) | Esquema instala do zero e nenhum objeto fica inválido | `01_instalacao.log` |
| `10_testes_automatizados.sql` | **47 verificações** dos packages, triggers e Dynamic SQL | `02_testes_plsql.log` |
| `09_consultas_demonstracao.sql` | Script de demonstração roda sem erro de compilação | `03_demonstracao.log` |
| Sobe o jar com o perfil `oracle` | **Deploy da API integrado ao Oracle** | `04_api.log` |
| [`scripts/ci/smoke-test.mjs`](../scripts/ci/smoke-test.mjs) | REST → JDBC → `PKG_MONITORAMENTO` / `PKG_RELATORIOS` → triggers, de ponta a ponta | `05_smoke_test.log` |
| Consulta `ROUTINE_EXECUTION_LOG` e `HEALTH_ALERT_AUDIT` | Evidência gravada no banco pela execução | `06_evidencias.log` |

O smoke test faz login JWT, lê pacientes do Oracle, envia uma leitura crítica
(os alertas são abertos pelo package PL/SQL), gera o relatório consolidado
(`engine = ORACLE_PLSQL`), confere que um período inválido vira HTTP 422 a
partir do `ORA-20003` e dispara a consolidação em lote.

### 5. `deploy` — entrega contínua (somente `main`)

Executa apenas quando **todos** os jobs anteriores passam, no *environment*
`producao` (onde é possível exigir aprovação manual em
*Settings → Environments*).

1. **Imagem Docker da API** ([`backend/Dockerfile`](../backend/Dockerfile))
   publicada no GitHub Container Registry:
   `ghcr.io/<dono>/smarthas-api:latest` e `:<sha do commit>`.
2. **Banco Oracle de destino** via SQLcl:
   - `incremental` (padrão): [`deploy.sql`](../database/oracle/deploy.sql) —
     cria só o que falta e recompila packages e triggers, **sem apagar dados**;
   - `completo` (somente no disparo manual): `instalar.sql` — reinstala do zero.
3. **API**: aciona o *deploy hook* do provedor (Render, Railway, Fly.io...),
   que puxa a imagem nova.

Os passos 2 e 3 só rodam se os *secrets* existirem; sem eles o resumo indica
"ignorado" e o job continua verde.

## Secrets

Em *Settings → Secrets and variables → Actions*:

| Secret | Exemplo | Uso |
|---|---|---|
| `ORACLE_DEPLOY_CONNECT` | `oracle.fiap.com.br:1521/ORCL` | Banco de destino (EZConnect) |
| `ORACLE_DEPLOY_USER` | `rm000000` | Usuário do esquema |
| `ORACLE_DEPLOY_PASSWORD` | — | Senha |
| `DEPLOY_WEBHOOK_URL` | `https://api.render.com/deploy/srv-...` | Deploy hook da API |

O banco do job `oracle` é um container efêmero criado e destruído a cada
execução; suas credenciais fixas no workflow não dão acesso a nenhum ambiente
real. Nenhuma credencial real fica no repositório.

## Logs e relatórios de execução

Cada execução produz:

- **Resumo** (aba *Summary*): cobertura do back-end, contagem de testes do
  painel e do app, tabela de testes PL/SQL e smoke test, e o resultado do
  deploy (imagem publicada, banco, API).
- **Check "Testes JUnit (back-end)"** no commit/PR, com cada teste.
- **Artefatos** para download:

| Artefato | Conteúdo | Retenção |
|---|---|---|
| `backend-relatorios` | Log do build, relatório HTML dos testes, JaCoCo (HTML/XML), XML JUnit | 30 dias |
| `backend-jar` | `smarthas-api.jar` | 7 dias |
| `web-admin` | `dist/` e logs de teste/build | 7 dias |
| `flutter-logs` | Análise estática e testes | 7 dias |
| `oracle-logs` | Logs 00–07 da tabela acima, incluindo a API e o container Oracle | 30 dias |
| `deploy-logs` | Saída do SQLcl no banco de destino | 30 dias |

Além disso, o próprio banco guarda a trilha: `ROUTINE_EXECUTION_LOG` registra
cada execução de rotina (e o `DEPLOY_PIPELINE`), e `HEALTH_ALERT_AUDIT` cada
evento de alerta.

## Reproduzindo localmente

```bash
cd backend && gradlew.bat build                      # job backend
cd web-admin && npm ci && npm test && npm run build  # job web
cd smartcare_flutter && flutter analyze && flutter test
```

Com um Oracle local (ver [`database/oracle/README.md`](../database/oracle/README.md)):

```bash
cd database/oracle && sql smarthas/SENHA@localhost:1521/FREEPDB1 @instalar.sql
cd database/oracle && sql smarthas/SENHA@localhost:1521/FREEPDB1 @10_testes_automatizados.sql
backend\run-oracle.bat
node scripts/ci/smoke-test.mjs http://localhost:8080
```
