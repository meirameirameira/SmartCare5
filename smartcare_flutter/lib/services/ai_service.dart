import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AiService {
  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );

  static const _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static const _systemPrompt = '''
Você é o Assistente SmartCare 5.0, especialista em saúde do paciente João Silva, 68 anos, com diabetes tipo 2 e hipertensão leve.

Dados vitais atuais do paciente:
- Frequência cardíaca: 72 bpm (normal)
- SpO₂: 98.5% (normal)
- Glicemia: 104 mg/dL (levemente acima — ideal em jejum: 70–100)
- Pressão arterial: 120/80 mmHg (ótimo controle)
- Temperatura: 36.5°C
- Score de saúde: 84/100

Medicamentos em uso:
- Metformina 500mg (08:00 e 14:00 — com refeição)
- Losartana 50mg (20:00 — com jantar)

Diretrizes:
- Responda SEMPRE em português do Brasil
- Seja empático, claro e objetivo
- Dê respostas personalizadas usando os dados do paciente
- Para situações de emergência, oriente a ligar 192 (SAMU)
- Não substitua o médico — reforce consultas quando necessário
- Respostas curtas (máx 4 linhas) a menos que solicitado mais detalhes
''';

  static final _rng = Random();

  static Future<String> ask(String question) async {
    if (_apiKey.isEmpty) {
      debugPrint('[AiService] GEMINI_API_KEY não configurada — usando fallback');
      return _fallback(question);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [
                  {'text': _systemPrompt}
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
              'generationConfig': {
                'temperature': 0.7,
                'maxOutputTokens': 512,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            as String?;
        if (text != null && text.isNotEmpty) return text.trim();
      }

      debugPrint('[AiService] Gemini retornou ${response.statusCode}: ${response.body}');
      return _fallback(question);
    } catch (e) {
      debugPrint('[AiService] Erro na chamada Gemini: $e');
      return _fallback(question);
    }
  }

  static String _fallback(String question) {
    final q = question.toLowerCase();
    const responses = <String, String>{
      'glicemia': 'Sua glicemia atual é 104 mg/dL — levemente acima do ideal em jejum (70–100). Evite carboidratos simples à noite e consulte seu médico para ajuste.',
      'medicamento': 'Hoje você toma:\n• 08:00 — Metformina 500mg\n• 14:00 — Metformina 500mg\n• 20:00 — Losartana 50mg\n\nSua aderência está ótima esta semana!',
      'exercício': 'Para sua condição recomendo:\n• Caminhada 30 min após refeições\n• Natação 3x/semana\n• Evite alta intensidade sem supervisão médica.',
      'pressão': 'Sua pressão está excelente: 120/80 mmHg. Continue com a Losartana no horário e reduza o sódio na alimentação.',
      'coração': 'FC de repouso: 72 bpm — normal. Tendência estável nas últimas 2 semanas.',
      'sono': 'Sono inadequado eleva a pressão em até 15%. Meta: 7–8h por noite. Desligue telas 1h antes de dormir.',
    };

    for (final entry in responses.entries) {
      if (q.contains(entry.key)) return entry.value;
    }

    final generic = [
      'Posso te ajudar com informações sobre glicemia, pressão, medicamentos, exercícios ou sono. O que deseja saber?',
      'Com base nos seus dados de saúde, estou aqui para responder suas dúvidas. Tente ser mais específico sobre o que precisa.',
    ];
    return generic[_rng.nextInt(generic.length)];
  }
}
