# Smart HAS · SmartCare 5.0

Sistema de apoio à decisão em saúde domiciliar alinhado à Sociedade 5.0:
monitoramento contínuo de sinais vitais, alertas clínicos, teleconsulta e a
camada **AI Logistics Extension** para entrega inteligente de medicamentos.

A solução opera em três camadas independentes que consomem o mesmo contrato de
API:

| Módulo | Stack | Papel |
|---|---|---|
| [`backend/`](backend/) | Java 21 · Spring Boot 3.5 | API REST, persistência, regras clínicas, segurança JWT e painel Thymeleaf |
| [`smartcare_flutter/`](smartcare_flutter/README.md) | Flutter 3 · Dart 3 | Aplicativo do paciente |
| [`web-admin/`](web-admin/README.md) | Angular 20 | Painel administrativo da equipe assistencial |
| [`app/`](app/) | Kotlin · Android | Aplicativo Android da fase anterior |

Toda regra de negócio entra uma única vez, no back-end, e chega idêntica ao
aplicativo e ao painel.

---

## Como executar

Suba os módulos nesta ordem:

```bash
cd backend && gradlew.bat bootRun
```

```bash
cd web-admin && npm install && npm start
```

```bash
cd smartcare_flutter && flutter run --dart-define=SMARTHAS_API_URL=http://10.0.2.2:8080 --dart-define=SMARTHAS_EMAIL=felipe@smarthas.com --dart-define=SMARTHAS_PASSWORD=paciente123
```

Com `SMARTHAS_API_URL` definido, o aplicativo consome a API real: prontuário,
sinais vitais, alertas e os pedidos da camada AI Logistics são exatamente os
mesmos que a equipe vê no painel administrativo, e a confirmação de recebimento
feita pelo paciente atualiza o pedido no servidor.

Sem nenhuma variável definida, o aplicativo funciona integralmente em modo
demonstração: wearable simulado, catálogo local de entregas, assistente com base
de conhecimento local e notificações locais.

### Endereços

| Serviço | URL |
|---|---|
| API REST | http://localhost:8080/api/v1 |
| Swagger UI | http://localhost:8080/swagger-ui.html |
| Painel Thymeleaf (operação) | http://localhost:8080/painel |
| Painel Angular (administração) | http://localhost:4200 |

### Base de demonstração

O banco H2 de desenvolvimento não é versionado: na primeira execução o
`DemoDataLoader` popula pacientes, histórico de sinais vitais, pedidos da
camada AI Logistics e uma consulta agendada. Os alertas clínicos não são
escritos à mão — são gerados pelo próprio motor de regras a partir de uma
leitura alterada, de modo que todo clone parte do mesmo estado e o painel
nunca abre zerado. Para recomeçar do zero, apague `backend/data/`.

### Credenciais de demonstração

| Perfil | E-mail | Senha |
|---|---|---|
| ADMIN | `admin@smarthas.com` | `admin123` |
| PROFESSIONAL | `enfermagem@smarthas.com` | `enfermagem123` |
| PATIENT | `felipe@smarthas.com` | `paciente123` |

---

## Qualidade

```bash
cd backend && gradlew.bat test                            # 21 testes de integração
cd web-admin && npm install && npm test                   # 15 testes unitários
cd web-admin && npm run build                             # build de produção
cd smartcare_flutter && flutter analyze && flutter test   # 54 testes
```

Total: **90 testes automatizados** cobrindo regras clínicas, fluxo logístico,
segurança JWT, contrato da API e telas.

---

## Documentação

- **[Entrega final — Atividade 4](entregas/SmartHAS_Atividade4_Entrega_Final.docx)** —
  documento de encerramento: escopo, funcionalidades, arquitetura, execução,
  qualidade, limites declarados e roteiro para a Banca.

### Fase 5

- [Parte 1 — Aprimoramento da solução Flutter](entregas/Fase5_Parte1_Aprimoramentos.md)
- [Parte 2 — Back-end escalável com Spring Boot](entregas/Fase5_Parte2_Backend.md)
- [Parte 3 — Integração web com Angular](entregas/Fase5_Parte3_Angular.md)
