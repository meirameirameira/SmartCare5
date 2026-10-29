import '../entities/entities.dart';
import 'health_score_engine.dart';

/// Consolida um histórico de leituras no [ClinicalReport].
///
/// Espelha, no aparelho, a procedure `PRC_CONSOLIDAR_RELATORIO` e as functions
/// `FN_CALCULAR_SCORE_SAUDE` e `FN_TEMPO_NA_FAIXA` do Oracle: mesmas médias
/// com uma casa decimal, mesmo score e mesmo indicador de tempo na faixa.
/// É o que o app usa em modo demonstração, quando não há back-end.
class ClinicalReportEngine {
  const ClinicalReportEngine({this.scoreEngine = const HealthScoreEngine()});

  final HealthScoreEngine scoreEngine;

  /// [history] são as leituras do período, em qualquer ordem.
  ClinicalReport build({
    required Patient patient,
    required List<VitalReading> history,
    required int periodDays,
    int openAlerts = 0,
    int urgentAlerts = 0,
    int alertsInPeriod = 0,
    int deliveriesTotal = 0,
    int deliveriesDelivered = 0,
    DateTime? now,
  }) {
    final ordered = [...history]..sort((a, b) =>
        (a.measuredAt ?? DateTime(0)).compareTo(b.measuredAt ?? DateTime(0)));
    final latest = ordered.isEmpty ? null : ordered.last;
    final latestScore =
        latest == null ? null : scoreEngine.calculate(latest).score;
    final tir = glucoseTimeInRange(ordered);

    return ClinicalReport(
      patientName: patient.name,
      periodDays: periodDays,
      generatedAt: now ?? DateTime.now(),
      readings: ordered.length,
      averages: VitalAverages(
        heartRate: _average(ordered, (r) => r.heartRate),
        spO2: _average(ordered, (r) => r.spO2),
        glucose: _average(ordered, (r) => r.glucoseLevel),
        systolic: _average(ordered, (r) => r.bpSystolic),
        diastolic: _average(ordered, (r) => r.bpDiastolic),
        temperature: _average(ordered, (r) => r.temperature),
      ),
      latestScore: latestScore,
      averageScore:
          _average(ordered, (r) => scoreEngine.calculate(r).score),
      riskLevel: riskLabel(latestScore),
      glucoseTimeInRange: tir,
      openAlerts: openAlerts,
      urgentAlerts: urgentAlerts,
      alertsInPeriod: alertsInPeriod,
      deliveriesTotal: deliveriesTotal,
      deliveriesDelivered: deliveriesDelivered,
      summary: _summary(patient, latestScore, tir, periodDays, openAlerts,
          urgentAlerts),
      engine: ReportEngine.device,
    );
  }

  /// `FN_TEMPO_NA_FAIXA(paciente, 'GLUCOSE', dias)`: % das leituras com
  /// glicemia na faixa normal; `null` sem leituras.
  double? glucoseTimeInRange(List<VitalReading> history) {
    if (history.isEmpty) return null;
    const range = HealthScoreEngine.glucose;
    final inRange = history
        .where((r) =>
            r.glucoseLevel >= range.normalMin &&
            r.glucoseLevel <= range.normalMax)
        .length;
    return _round1(inRange * 100 / history.length);
  }

  /// `FN_ROTULO_NIVEL`: rótulo do nível de risco, ou `SEM DADOS`.
  String riskLabel(int? score) => score == null
      ? 'SEM DADOS'
      : HealthScoreEngine.labelFor(HealthScoreEngine.levelFor(score));

  String _summary(Patient patient, int? score, double? tir, int days,
      int openAlerts, int urgentAlerts) {
    final conditions = [...patient.conditions]..sort();
    final buffer = StringBuffer('${patient.name}, ${patient.age} anos');
    if (conditions.isNotEmpty) buffer.write(' (${conditions.join(', ')})');
    buffer.write(' | Score atual: ');
    buffer.write(score == null ? 'sem leituras' : '$score/100 - ${riskLabel(score)}');
    buffer.write(' | Glicemia na faixa: ');
    buffer.write(tir == null
        ? 'sem dados'
        : '${_decimalBr(tir)}% das leituras em $days dias');
    buffer.write(' | Alertas abertos: $openAlerts');
    if (urgentAlerts > 0) {
      buffer.write(' ($urgentAlerts urgente${urgentAlerts > 1 ? 's' : ''})');
    }
    return buffer.toString();
  }

  static double? _average(List<VitalReading> values, num Function(VitalReading) pick) {
    if (values.isEmpty) return null;
    final sum = values.fold<double>(0, (acc, r) => acc + pick(r));
    return _round1(sum / values.length);
  }

  /// `ROUND(x, 1)` do Oracle (meio para longe do zero).
  static double _round1(double value) => (value * 10).round() / 10;

  static String _decimalBr(double value) =>
      value.toStringAsFixed(1).replaceAll('.', ',');
}
