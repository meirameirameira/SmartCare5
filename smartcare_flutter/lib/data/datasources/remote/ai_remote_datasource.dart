import '../../../core/network/api_client.dart';
import '../../../domain/entities/entities.dart';
import '../../../domain/services/health_score_engine.dart';

/// Cliente do assistente generativo (Gemini) do SmartCare 5.0.
///
/// Diferenças em relação à versão anterior:
///  - o prompt de sistema é montado com os sinais vitais **reais** do paciente
///    no momento da pergunta, em vez de um bloco de texto fixo e desatualizado;
///  - transporte, retry e timeout ficam no [ApiClient];
///  - a decisão de cair no fallback offline é do repositório, não daqui.
class AiRemoteDataSource {
  AiRemoteDataSource(this._client);

  final ApiClient _client;

  static const apiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static bool get isConfigured => apiKey.isNotEmpty;

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  Future<String> ask(String question, {VitalReading? vitals}) {
    return _client.postJson(
      _endpoint,
      query: {'key': apiKey},
      body: {
        'system_instruction': {
          'parts': [
            {'text': buildSystemPrompt(vitals)}
          ]
        },
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': question}
            ]
          }
        ],
        'generationConfig': {'temperature': 0.7, 'maxOutputTokens': 512},
      },
      decode: (json) {
        final candidates = json['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw const _EmptyCompletion();
        }
        final content =
            (candidates.first as Map)['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        final text = (parts == null || parts.isEmpty)
            ? null
            : (parts.first as Map)['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          throw const _EmptyCompletion();
        }
        return text.trim();
      },
    );
  }

  /// Monta o contexto clínico enviado ao modelo, incluindo a classificação de
  /// cada sinal vital feita pelo motor de regras local.
  static String buildSystemPrompt(VitalReading? vitals) {
    final buffer = StringBuffer()
      ..writeln('Você é o Assistente SmartCare 5.0, apoio à saúde de um paciente '
          'com diabetes tipo 2 e hipertensão leve.');

    if (vitals != null) {
      const engine = HealthScoreEngine();
      final score = engine.calculate(vitals);
      buffer.writeln('\nLeitura mais recente do wearable:');
      for (final e in engine.evaluateVitals(vitals)) {
        buffer.writeln('- ${e.metric}: ${e.displayValue} ${e.unit} '
            '(${_statusLabel(e.status)})');
      }
      buffer.writeln('- Score de saúde calculado: ${score.score}/100 '
          '(${score.label})');
    } else {
      buffer.writeln('\nNenhuma leitura recente disponível no momento.');
    }

    buffer.writeln('''

Medicamentos em uso:
- Metformina 500mg (08:00 e 14:00, com refeição)
- Losartana 50mg (20:00, com o jantar)

Diretrizes:
- Responda SEMPRE em português do Brasil.
- Seja empático, claro e objetivo (máximo 4 linhas, salvo pedido de detalhe).
- Use os dados acima para personalizar a resposta.
- Em emergência, oriente ligar 192 (SAMU).
- Nunca substitua o médico: reforce o acompanhamento profissional.''');

    return buffer.toString();
  }

  static String _statusLabel(VitalStatus status) => switch (status) {
        VitalStatus.normal => 'normal',
        VitalStatus.attention => 'atenção',
        VitalStatus.critical => 'crítico',
      };
}

class _EmptyCompletion implements Exception {
  const _EmptyCompletion();
  @override
  String toString() => 'O assistente retornou uma resposta vazia.';
}
