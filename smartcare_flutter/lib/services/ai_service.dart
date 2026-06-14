import 'dart:math';

/// Serviço de IA do SmartHAS.
/// Em produção: conecta ao backend FastAPI com modelos de ML e LLM.
/// Em demo: respostas contextuais pré-definidas com lógica de matching.
class AiService {
  static final _rng = Random();

  static const _responses = <String, String>{
    'glicemia': 'Com base nos seus dados recentes, sua glicemia média nas últimas 24h foi de 108 mg/dL — levemente acima do ideal (70–100 mg/dL em jejum). Recomendo evitar carboidratos simples à noite.',
    'medicamento': 'Hoje você deve tomar:\n• 08:00 — Metformina 500mg (com café)\n• 14:00 — Metformina 500mg (com almoço)\n• 20:00 — Losartana 50mg (com jantar)\n\nSua aderência está em 96% esta semana. 👏',
    'exercício': 'Para sua condição (diabetes tipo 2 + hipertensão leve), recomendo:\n• Caminhada leve 30 min após refeições\n• Natação ou hidroginástica 3x/semana\n• Evite exercícios de alta intensidade sem supervisão médica.',
    'sono': 'O sono inadequado pode elevar a pressão arterial em até 15%. Sua meta: 7–8h por noite. Dica: desligue telas 1h antes de dormir e mantenha horários regulares.',
    'pressão': 'Sua última medição: 120/80 mmHg — excelente controle! Lembre-se de tomar Losartana no horário certo e evitar excesso de sódio.',
    'coração': 'Sua frequência cardíaca de repouso está em 72 bpm — dentro da faixa normal (60–100 bpm). A tendência das últimas 2 semanas é estável.',
  };

  static Future<String> ask(String question) async {
    // Simula latência de IA
    await Future.delayed(Duration(milliseconds: 800 + _rng.nextInt(600)));

    final q = question.toLowerCase();

    for (final entry in _responses.entries) {
      if (q.contains(entry.key)) return entry.value;
    }

    // Resposta genérica contextual
    final generic = [
      'Com base no seu perfil de saúde, posso te ajudar com informações sobre seus sinais vitais, medicamentos ou hábitos. Pode perguntar!',
      'Analisando seus dados... Para uma resposta mais precisa sobre "$question", recomendo consultar seu médico na próxima consulta. Posso ajudar com algo mais específico?',
      'Boa pergunta! No SmartHAS monitoramos continuamente seus dados para fornecer insights personalizados. Tente perguntar sobre glicemia, pressão, medicamentos ou exercícios.',
    ];
    return generic[_rng.nextInt(generic.length)];
  }
}
