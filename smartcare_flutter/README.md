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

```
smartcare_flutter/
├── lib/
│   ├── main.dart                 # Entry point e injeção de Providers
│   ├── screens/                  # Telas da UI
│   │   ├── home_screen.dart      # Painel de sinais vitais
│   │   ├── chat_screen.dart      # Assistente SmartCare (IA)
│   │   ├── map_screen.dart       # Google Maps + dispositivos IoT
│   │   ├── medications_screen.dart
│   │   ├── login_screen.dart
│   │   └── credits_screen.dart
│   ├── providers/                # Gerenciamento de estado (Provider)
│   │   ├── home_provider.dart
│   │   ├── chat_provider.dart
│   │   └── map_provider.dart
│   ├── services/                 # Integração com APIs externas
│   │   ├── ai_service.dart       # Gemini 2.0 Flash + fallback
│   │   ├── vitals_service.dart   # Sinais vitais simulados
│   │   └── fcm_service.dart      # Notificações push
│   └── models/                   # Entidades de dados
├── android/
│   ├── local.properties          # ⚠️ NÃO commitado — criar manualmente
│   └── app/
│       ├── build.gradle          # Injeção da Maps API key
│       └── google-services.json  # ⚠️ NÃO commitado — baixar do Firebase
└── web/
    └── index.html                # Maps JS API (usa YOUR_MAPS_API_KEY no repo)
```

---

## Funcionalidades

- **Painel de Vitais** — FC, SpO₂, Glicemia, PA e Temperatura atualizados em tempo real com score de saúde
- **Assistente IA** — Chat integrado ao Google Gemini 2.0 Flash com contexto dos dados do paciente
- **Mapa** — Google Maps com marcadores dos dispositivos IoT do paciente
- **Medicamentos** — Agenda de medicamentos com horários e aderência semanal
- **Notificações Push** — Alertas de saúde via Firebase Cloud Messaging

---

## Observações conhecidas

| Situação | Comportamento |
|---|---|
| `GEMINI_API_KEY` ausente ou com quota zerada | Assistente usa fallback por palavras-chave |
| `GOOGLE_MAPS_API_KEY` ausente | Mapa carrega com aviso `InvalidKey` |
| NumbersAPI bloqueada por CORS (Flutter Web) | Vitais usam geração local aleatória |
| Firebase não configurado | App inicializa normalmente sem push |
