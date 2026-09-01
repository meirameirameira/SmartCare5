# Smart HAS · Painel Administrativo (Angular)

Interface web da equipe assistencial. Consome **a mesma API REST** do aplicativo
Flutter (`backend/`), com o mesmo modelo de autenticação por JWT.

## Pré-requisitos

| Ferramenta | Versão |
|---|---|
| Node.js | 20+ |
| npm | 10+ |
| Back-end Smart HAS | rodando em `http://localhost:8080` |

## Como executar

```bash
cd web-admin
npm install
npm start
```

O painel sobe em `http://localhost:4200` — origem já autorizada no CORS do
back-end, sem nenhum ajuste adicional.

Atalho no Windows: `run-dev.bat`.

### Credenciais de demonstração

| Perfil | E-mail | Senha | Acesso |
|---|---|---|---|
| Equipe assistencial | `enfermagem@smarthas.com` | `enfermagem123` | Leitura e escrita |
| Administração | `admin@smarthas.com` | `admin123` | Escrita + exclusão |
| Paciente | `felipe@smarthas.com` | `paciente123` | Somente o próprio prontuário |

O botão **Usar credenciais de demonstração** na tela de acesso preenche o
primeiro par automaticamente.

### Apontar para outro back-end

Edite `src/environments/environment.ts`:

```ts
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8080',
};
```

## Estrutura

```
web-admin/src/app/
├── app.ts / app.html / app.css     # casca: cabeçalho de navegação + <router-outlet>
├── app.config.ts                   # providers: rotas, HttpClient, interceptor
├── app.routes.ts                   # /login, /home, /admin, /entregas
├── core/
│   ├── models/api-models.ts        # contratos TypeScript espelhando os DTOs da API
│   ├── services/
│   │   ├── auth.service.ts         # POST /auth/login, guarda token e perfil
│   │   ├── patient.service.ts      # CRUD de prontuários e alertas
│   │   ├── delivery.service.ts     # pedidos e mudança de status
│   │   └── analytics.service.ts    # GET /analytics/overview
│   ├── interceptors/auth.interceptor.ts  # injeta Bearer token, trata 401
│   ├── guards/auth.guard.ts        # bloqueia rotas internas sem sessão
│   └── util/erro-api.ts            # traduz o envelope de erro da API
└── pages/
    ├── login/                      # formulário de acesso
    ├── home/                       # indicadores da operação
    ├── admin/                      # lista + formulário de pacientes
    └── entregas/                   # tabela de pedidos com filtro e avanço de etapa
```

## Recursos Angular aplicados

| Recurso | Onde |
|---|---|
| **Interpolação** `{{ }}` | Valores dos indicadores, nomes, status e contadores |
| **Property binding** `[ ]` | `[disabled]="carregando"`, `[ngClass]`, `[class.invalido]` |
| **Event binding** `( )` | `(click)="carregar()"`, `(ngSubmit)="salvar()"`, `(keyup.enter)` |
| **Two-way** `[( )]` | Campos de login, busca de pacientes, formulário e filtro de status |
| **`*ngIf`** | Faixas de erro e sucesso, estados vazios, alternância entre criar e editar |
| **`*ngFor`** | Cartões de indicadores, lista de pacientes, condições, trilha e pedidos |
| **`HttpClient`** | Um serviço por domínio, devolvendo `Observable` tipado |
| **`HttpInterceptorFn`** | Autenticação e tratamento central de 401 |
| **`CanActivateFn`** | Proteção das rotas internas |
| **Pipes** | `date: 'HH:mm:ss'` no horário da última atualização |

## Telas

### `/login`
Formulário com `[(ngModel)]`, botão desabilitado durante a requisição e
tradução do HTTP 401 da API em mensagem clara. Ao autenticar, guarda o token e
redireciona para a rota originalmente pedida.

### `/home`
Quatro indicadores vindos de `GET /api/v1/analytics/overview` (pacientes
monitorados, alertas em aberto, entregas em rota, consultas agendadas), a
contagem de entregas por status e atalhos para as demais telas. O cartão de
alertas fica destacado em âmbar quando há alerta urgente aberto.

### `/admin`
Lista de prontuários com busca e o **formulário funcional** de cadastro e
edição: validação local antes do envio e exibição campo a campo dos
`fieldErrors` devolvidos pela API em HTTP 400. Exclusão restrita ao perfil
`ADMIN` — o botão fica desabilitado para quem não tem permissão.

### `/entregas`
Consolida os pedidos de todos os pacientes, com filtro por status
(`[(ngModel)]` no `<select>`), trilha visual das quatro etapas e ações de
avançar ou cancelar. Uma transição inválida volta como HTTP 422 e é exibida ao
operador em vez de silenciada.

## Feedback visual

- Faixa vermelha para erro, com ação de nova tentativa.
- Faixa verde de confirmação após salvar ou avançar um pedido.
- Estado de carregamento explícito e botões desabilitados em cinza durante a
  requisição.
- Mensagem de lista vazia diferente da de lista carregando.
- Identidade visual compartilhada com o aplicativo: mesmos verdes e as mesmas
  etiquetas de severidade.

## Build de produção

```bash
npm run build
```

Saída em `dist/smarthas-web-admin` (~369 kB iniciais, 98 kB transferidos).
