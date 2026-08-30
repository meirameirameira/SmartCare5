import '../../../domain/entities/entities.dart';
import '../../../domain/services/health_score_engine.dart';

/// Base de conhecimento local do assistente.
///
/// Usada quando a API generativa não está configurada ou está indisponível —
/// o app continua respondendo, agora com os **valores atuais** do paciente em
/// vez de textos fixos.
class AiFallbackDataSource {
  const AiFallbackDataSource({this.scoreEngine = const HealthScoreEngine()});

  final HealthScoreEngine scoreEngine;

  String answer(String question, {VitalReading? vitals}) {
    final q = _normalize(question);

    if (_matches(q, ['glicemia', 'glicose', 'acucar', 'açúcar'])) {
      final value = vitals?.glucoseLevel;
      final status = value == null
          ? null
          : HealthScoreEngine.glucose.classify(value.toDouble());
      if (value == null) {
        return 'Ainda não recebi uma leitura de glicemia do seu sensor. '
            'Assim que o wearable sincronizar eu te aviso.';
      }
      return switch (status!) {
        VitalStatus.normal => 'Sua glicemia atual é $value mg/dL — dentro da faixa '
            'de referência (70–120). Mantenha a rotina alimentar e a Metformina nos horários.',
        VitalStatus.attention =>
          'Sua glicemia atual é $value mg/dL — acima da faixa ideal (70–120). '
              'Evite carboidratos simples agora e faça uma caminhada leve de 15 min.',
        VitalStatus.critical =>
          'Sua glicemia está em $value mg/dL, fora da faixa segura. '
              'Entre em contato com seu médico; se houver sintomas, ligue 192 (SAMU).',
      };
    }

    if (_matches(q, ['medicamento', 'remedio', 'remédio', 'dose', 'metformina', 'losartana'])) {
      return 'Sua agenda de hoje:\n'
          '• 08:00 — Metformina 500mg\n'
          '• 14:00 — Metformina 500mg\n'
          '• 20:00 — Losartana 50mg\n\n'
          'Tome sempre junto das refeições, com água.';
    }

    if (_matches(q, ['exercicio', 'exercício', 'atividade', 'caminhada', 'treino'])) {
      return 'Para o seu perfil recomendo:\n'
          '• Caminhada de 30 min após as refeições principais\n'
          '• Atividade aeróbica leve 3x por semana\n'
          '• Evitar alta intensidade sem liberação médica.';
    }

    if (_matches(q, ['pressao', 'pressão', 'hipertensao', 'hipertensão'])) {
      final s = vitals?.bpSystolic;
      final d = vitals?.bpDiastolic;
      if (s == null || d == null) {
        return 'Ainda não tenho uma medição de pressão recente. Faça uma aferição '
            'pelo aparelho conectado para eu avaliar.';
      }
      final status = HealthScoreEngine.systolic.classify(s.toDouble());
      final prefix = 'Sua pressão mais recente é $s/$d mmHg';
      return switch (status) {
        VitalStatus.normal => '$prefix — bem controlada. '
            'Mantenha a Losartana às 20h e reduza o sódio.',
        VitalStatus.attention => '$prefix — levemente elevada. '
            'Reduza sal e cafeína hoje e refaça a medição em 2h.',
        VitalStatus.critical => '$prefix — fora da faixa segura. '
            'Procure atendimento médico; em caso de dor no peito, ligue 192.',
      };
    }

    if (_matches(q, ['coracao', 'coração', 'cardiaca', 'cardíaca', 'batimento', 'bpm'])) {
      final hr = vitals?.heartRate;
      return hr == null
          ? 'Sem leitura recente de frequência cardíaca no momento.'
          : 'Sua frequência cardíaca é $hr bpm. Faixa de repouso esperada: 60–100 bpm.';
    }

    if (_matches(q, ['sono', 'dormir', 'insonia', 'insônia'])) {
      return 'Dormir menos de 6h eleva a pressão arterial em até 15%. '
          'Meta: 7–8h por noite, sem telas na última hora antes de deitar.';
    }

    if (_matches(q, ['score', 'saude geral', 'saúde geral', 'como estou'])) {
      if (vitals == null) return 'Ainda não consigo calcular seu score sem leituras.';
      final score = scoreEngine.calculate(vitals);
      final worst = score.penalties.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final detail = worst.isEmpty
          ? 'Nenhuma métrica fora da faixa.'
          : 'Principal ponto de atenção: ${worst.first.key}.';
      return 'Seu score de saúde agora é ${score.score}/100 (${score.label}). $detail';
    }

    return 'Posso ajudar com glicemia, pressão, frequência cardíaca, medicamentos, '
        'exercícios, sono ou seu score de saúde. Sobre qual deles você quer falar?';
  }

  bool _matches(String question, List<String> keywords) =>
      keywords.any(question.contains);

  String _normalize(String value) => value.toLowerCase().trim();
}
