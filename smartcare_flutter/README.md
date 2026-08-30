# SmartCare 5.0

## Pré-requisitos

| Ferramenta | Versão mínima |
|---|---|
| Flutter SDK | 3.19+ |
| Dart SDK | 3.3+ |
| Android SDK | API 21+ (Android 5.0) |
| Java | 17+ |
| Git | qualquer |

Verifique sua instalação:
```bash
flutter doctor
```

---

## 1. Clonar o repositório

```bash
git clone https://github.com/meirameirameira/SmartCare5.git
cd SmartCare5/smartcare_flutter
```

---

## 2. Configurar chaves de API (obrigatório)

Crie o arquivo `android/local.properties` com o seguinte conteúdo (o arquivo **não é commitado** por segurança):

```properties
sdk.dir=C:\\Users\\SEU_USUARIO\\AppData\\Local\\Android\\sdk
flutter.sdk=C:\\Users\\SEU_USUARIO\\develop\\flutter

# Google Maps — obtenha em console.cloud.google.com
GOOGLE_MAPS_API_KEY=SUA_CHAVE_MAPS_AQUI

# Gemini AI — obtenha em aistudio.google.com/apikey
GEMINI_API_KEY=SUA_CHAVE_GEMINI_AQUI
```

> **Nota:** Ajuste os caminhos `sdk.dir` e `flutter.sdk` para o seu ambiente.  
> Sem `GEMINI_API_KEY`, o assistente de IA opera em modo fallback com respostas pré-definidas.  
> Sem `GOOGLE_MAPS_API_KEY`, o mapa exibe o aviso `InvalidKey` mas o app continua funcional.

---

## 3. Instalar dependências

```bash
flutter pub get
```

---

## 4. Rodar o app

### Android (emulador ou dispositivo físico)

```bash
flutter run
```

Para selecionar um dispositivo específico:
```bash
flutter devices          # lista os dispositivos disponíveis
flutter run -d <device_id>
```

### Web (Chrome) — sem necessidade de Android SDK

```bash
flutter run -d chrome --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI
```

> No modo web, a chave Gemini deve ser passada via `--dart-define` pois o `local.properties` só é lido em builds Android.

### Build Android APK

```bash
flutter build apk --release \
  --dart-define=GEMINI_API_KEY=SUA_CHAVE_AQUI
```

O APK gerado estará em `build/app/outputs/flutter-apk/app-release.apk`.

---

## 5. Firebase (opcional)

O app usa Firebase para notificações push. Sem configuração, ele inicializa com fallback gracioso.

Para habilitar Firebase:
1. Crie um projeto em [console.firebase.google.com](https://console.firebase.google.com)
2. Registre o app com package name `com.smarthas.smartcare_flutter`
3. Baixe `google-services.json` e coloque em `android/app/`

---

## Estrutura do projeto

Arquitetura em camadas (domínio puro, dados e apresentação), com inversão de dependência:

```
smartcare_flutter/
├── lib/
│   ├── main.dart                    # bootstrap de plataforma (Firebase, notificações)
│   ├── app.dart                     # composição de providers, temas e rotas
│   ├── core/                        # infraestrutura transversal
│   │   ├── di/injector.dart         # Composition Root — decide as implementações
│   │   ├── error/failures.dart      # AppFailure selada (rede, timeout, servidor, cache…)
│   │   ├── result/result.dart       # Result<T> = Ok | Err
│   │   ├── state/view_state.dart    # ViewState<T> = Idle | Loading | Ready | Failed
│   │   ├── network/api_client.dart  # HTTP único com retry e backoff exponencial
│   │   ├── storage/local_cache.dart # cache offline-first (SharedPreferences / memória)
│   │   ├── notifications/           # canal único de notificações locais e FCM
│   │   ├── theme/app_theme.dart     # temas claro e escuro + cores semânticas de saúde
│   │   └── router/app_router.dart   # rotas nomeadas (go_router)
│   ├── domain/                      # regras de negócio, sem dependência de Flutter
│   │   ├── entities/
│   │   ├── repositories/            # contratos usados pela UI
│   │   └── services/
│   │       ├── health_score_engine.dart  # score 0–100 por faixas clínicas
│   │       └── alert_engine.dart         # alertas dinâmicos + agenda de medicação
│   ├── data/
│   │   ├── datasources/remote/      # Open-Meteo, gateway IoT/wearable, Gemini
│   │   ├── datasources/local/       # base de conhecimento offline, catálogo demo
│   │   └── repositories/            # implementações dos contratos de domínio
│   └── presentation/
│       ├── providers/               # estado de tela (Provider/ChangeNotifier)
│       ├── screens/                 # home, delivery, consulta, analytics, chat, mapa,
│       │                            # preferências, créditos
│       └── widgets/
├── test/                            # 45 testes: domínio, dados, providers e widgets
├── android/
│   ├── local.properties             # ⚠️ NÃO commitado — criar manualmente
│   └── app/
│       ├── build.gradle             # injeção da Maps API key
│       └── google-services.json     # ⚠️ NÃO commitado — baixar do Firebase
└── web/
    └── index.html                   # Maps JS API
```

### Variáveis de compilação (`--dart-define`)

| Variável | Sem ela | Com ela |
|---|---|---|
| `GEMINI_API_KEY` | Assistente usa a base de conhecimento local, já contextualizada com os vitais atuais | Respostas geradas pelo Gemini 2.0 Flash |
| `SMARTCARE_API_URL` | Sinais vitais vêm do simulador de wearable | Leituras vêm do gateway IoT REST |
| `GOOGLE_MAPS_API_KEY` | Mapa carrega com aviso `InvalidKey` | Mapa completo |

---

## Funcionalidades

- **Dashboard de vitais** — FC, SpO₂, glicemia, PA e temperatura atualizados automaticamente, com chips
  coloridos pela classificação clínica de cada sinal.
- **Score de saúde calculado** — motor de regras converte as leituras em um score 0–100, com tendência e
  indicação de qual métrica mais reduz a pontuação.
- **Alertas dinâmicos** — gerados a partir dos sinais fora da faixa e da agenda de medicação, ordenados por
  severidade e enviáveis como notificação.
- **Modo offline-first** — sem rede, o app exibe a última leitura salva, informa o horário e oferece
  atualizar; erros aparecem com ação de nova tentativa.
- **Assistente SmartCare** — Gemini 2.0 Flash quando configurado, com fallback local; em ambos os casos a
  resposta usa os valores medidos no instante da pergunta. Histórico persistido entre sessões.
- **Analytics** — séries de 7/14/30 dias terminando na medição real mais recente, com insights derivados do
  score.
- **Mapa IoT** — dispositivos do paciente, farmácia e hospitais de referência sobre o Google Maps.
- **Entregas & Home Care** — rastreio do pedido de medicamentos e próxima visita domiciliar.
- **Preferências** — tema claro/escuro/automático, escala de texto de 90% a 130% (acessibilidade) e
  controle de notificações, tudo persistido no dispositivo.

---

## Qualidade

```bash
flutter analyze   # No issues found!
flutter test      # All tests passed! (45)
```

---

## Observações conhecidas

| Situação | Comportamento |
|---|---|
| `GEMINI_API_KEY` ausente ou com quota zerada | Assistente usa fallback por palavras-chave |
| `GOOGLE_MAPS_API_KEY` ausente | Mapa carrega com aviso `InvalidKey` |
| `SMARTCARE_API_URL` ausente | Vitais vêm do simulador determinístico de wearable |
| Firebase não configurado | App inicializa normalmente sem push |
