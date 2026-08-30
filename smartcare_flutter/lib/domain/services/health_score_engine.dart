import '../entities/entities.dart';

/// Faixa de referência clínica de um sinal vital.
///
/// Modelada como dado (e não como `if` solto no meio da UI) para que as regras
/// possam ser lidas, testadas e ajustadas em um único lugar.
class VitalRange {
  const VitalRange({
    required this.metric,
    required this.unit,
    required this.normalMin,
    required this.normalMax,
    required this.attentionMin,
    required this.attentionMax,
    required this.weight,
  });

  final String metric;
  final String unit;

  /// Limites da faixa considerada normal (inclusiva).
  final double normalMin;
  final double normalMax;

  /// Limites da faixa de atenção; fora dela o valor é crítico.
  final double attentionMin;
  final double attentionMax;

  /// Peso do sinal no score final (0–100).
  final int weight;

  VitalStatus classify(double value) {
    if (value >= normalMin && value <= normalMax) return VitalStatus.normal;
    if (value >= attentionMin && value <= attentionMax) return VitalStatus.attention;
    return VitalStatus.critical;
  }
}

/// Motor de regras que converte sinais vitais brutos em um score de saúde.
///
/// Antes o score `84/100` era uma constante hardcoded no provider. Agora ele é
/// derivado das leituras reais do wearable, é auditável (expõe as penalidades
/// por métrica) e é coberto por testes unitários — sem qualquer dependência de
/// Flutter, o que mantém o domínio puro.
class HealthScoreEngine {
  const HealthScoreEngine();

  static const heartRate = VitalRange(
    metric: 'Freq. cardíaca',
    unit: 'bpm',
    normalMin: 60,
    normalMax: 100,
    attentionMin: 50,
    attentionMax: 110,
    weight: 18,
  );

  static const spO2 = VitalRange(
    metric: 'SpO₂',
    unit: '%',
    normalMin: 95,
    normalMax: 100,
    attentionMin: 90,
    attentionMax: 100,
    weight: 22,
  );

  static const glucose = VitalRange(
    metric: 'Glicemia',
    unit: 'mg/dL',
    normalMin: 70,
    normalMax: 120,
    attentionMin: 60,
    attentionMax: 180,
    weight: 22,
  );

  static const systolic = VitalRange(
    metric: 'Pressão sistólica',
    unit: 'mmHg',
    normalMin: 90,
    normalMax: 129,
    attentionMin: 85,
    attentionMax: 139,
    weight: 18,
  );

  static const diastolic = VitalRange(
    metric: 'Pressão diastólica',
    unit: 'mmHg',
    normalMin: 60,
    normalMax: 84,
    attentionMin: 55,
    attentionMax: 89,
    weight: 10,
  );

  static const temperature = VitalRange(
    metric: 'Temperatura',
    unit: '°C',
    normalMin: 35.5,
    normalMax: 37.5,
    attentionMin: 35.0,
    attentionMax: 38.5,
    weight: 10,
  );

  /// Avalia cada sinal vital individualmente, com justificativa em pt-BR.
  List<VitalEvaluation> evaluateVitals(VitalReading v) => [
        _evaluate(heartRate, v.heartRate.toDouble(), v.heartRate.toString()),
        _evaluate(spO2, v.spO2, v.spO2.toStringAsFixed(1)),
        _evaluate(glucose, v.glucoseLevel.toDouble(), v.glucoseLevel.toString()),
        _evaluate(systolic, v.bpSystolic.toDouble(), v.bpSystolic.toString()),
        _evaluate(diastolic, v.bpDiastolic.toDouble(), v.bpDiastolic.toString()),
        _evaluate(temperature, v.temperature, v.temperature.toStringAsFixed(1)),
      ];

  /// Calcula o score consolidado (0–100) a partir das leituras.
  ///
  /// [previousScore], quando informado, define a tendência exibida no card.
  HealthScore calculate(VitalReading v, {int? previousScore}) {
    final evaluations = evaluateVitals(v);
    final penalties = <String, int>{};

    var total = 100;
    for (final e in evaluations) {
      final range = _rangeFor(e.metric);
      final penalty = switch (e.status) {
        VitalStatus.normal => 0,
        VitalStatus.attention => (range.weight * 0.4).round(),
        VitalStatus.critical => range.weight,
      };
      if (penalty > 0) penalties[e.metric] = penalty;
      total -= penalty;
    }

    final score = total.clamp(0, 100);
    final level = levelFor(score);

    return HealthScore(
      score: score,
      level: level,
      label: labelFor(level),
      trend: _trend(score, previousScore),
      penalties: penalties,
    );
  }

  static HealthLevel levelFor(int score) {
    if (score >= 90) return HealthLevel.excellent;
    if (score >= 75) return HealthLevel.good;
    if (score >= 60) return HealthLevel.medium;
    if (score >= 40) return HealthLevel.low;
    return HealthLevel.critical;
  }

  static String labelFor(HealthLevel level) => switch (level) {
        HealthLevel.excellent => 'EXCELENTE',
        HealthLevel.good => 'BOM',
        HealthLevel.medium => 'MODERADO',
        HealthLevel.low => 'ATENÇÃO',
        HealthLevel.critical => 'CRÍTICO',
      };

  TrendDirection _trend(int score, int? previous) {
    if (previous == null || (score - previous).abs() <= 2) {
      return TrendDirection.stable;
    }
    return score > previous ? TrendDirection.up : TrendDirection.down;
  }

  VitalEvaluation _evaluate(VitalRange range, double value, String display) {
    final status = range.classify(value);
    return VitalEvaluation(
      metric: range.metric,
      displayValue: display,
      unit: range.unit,
      status: status,
      rationale: switch (status) {
        VitalStatus.normal =>
          'Dentro da faixa de referência (${_fmt(range.normalMin)}–${_fmt(range.normalMax)} ${range.unit}).',
        VitalStatus.attention =>
          'Fora da faixa ideal (${_fmt(range.normalMin)}–${_fmt(range.normalMax)} ${range.unit}). Monitorar.',
        VitalStatus.critical =>
          'Valor crítico para a faixa de referência (${_fmt(range.normalMin)}–${_fmt(range.normalMax)} ${range.unit}).',
      },
    );
  }

  VitalRange _rangeFor(String metric) => switch (metric) {
        'Freq. cardíaca' => heartRate,
        'SpO₂' => spO2,
        'Glicemia' => glucose,
        'Pressão sistólica' => systolic,
        'Pressão diastólica' => diastolic,
        _ => temperature,
      };

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
