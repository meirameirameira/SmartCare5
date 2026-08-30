import '../entities/entities.dart';
import 'health_score_engine.dart';

/// Horário de uma dose prescrita ao paciente.
class MedicationSchedule {
  const MedicationSchedule({
    required this.name,
    required this.dosage,
    required this.hour,
    required this.minute,
  });

  final String name;
  final String dosage;
  final int hour;
  final int minute;

  String get timeLabel =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Gera os alertas do dashboard a partir do estado real do paciente.
///
/// Antes a lista de alertas era literal e nunca mudava. Agora ela é derivada
/// das leituras do wearable e da agenda de medicação, o que torna o app
/// realmente reativo — e testável sem UI.
class AlertEngine {
  const AlertEngine({this.scoreEngine = const HealthScoreEngine()});

  final HealthScoreEngine scoreEngine;

  static const defaultMedications = [
    MedicationSchedule(name: 'Metformina', dosage: '500mg', hour: 8, minute: 0),
    MedicationSchedule(name: 'Metformina', dosage: '500mg', hour: 14, minute: 0),
    MedicationSchedule(name: 'Losartana', dosage: '50mg', hour: 20, minute: 0),
  ];

  /// Constrói a lista de alertas ordenada por severidade (urgente primeiro).
  ///
  /// [now] é injetável para deixar a geração determinística nos testes.
  List<HealthAlert> build(
    VitalReading vitals, {
    DateTime? now,
    List<MedicationSchedule> medications = defaultMedications,
  }) {
    final clock = now ?? DateTime.now();
    final alerts = <HealthAlert>[];

    for (final e in scoreEngine.evaluateVitals(vitals)) {
      if (e.status == VitalStatus.normal) continue;
      alerts.add(HealthAlert(
        id: 'vital-${e.metric}',
        type: e.status == VitalStatus.critical ? AlertType.urgent : AlertType.warning,
        title: '${e.metric}: ${e.displayValue} ${e.unit}',
        description: e.status == VitalStatus.critical
            ? '${e.rationale} Se houver sintomas, ligue 192 (SAMU).'
            : e.rationale,
        timeLabel: _hhmm(vitals.measuredAt ?? clock),
        actionLabel: 'Ver detalhes',
      ));
    }

    final nextDose = _nextDose(medications, clock);
    if (nextDose != null) {
      alerts.add(HealthAlert(
        id: 'med-${nextDose.name}-${nextDose.timeLabel}',
        type: AlertType.info,
        title: 'Medicamento às ${nextDose.timeLabel}',
        description:
            '${nextDose.name} ${nextDose.dosage} — tomar com água, junto da refeição.',
        timeLabel: nextDose.timeLabel,
      ));
    }

    if (alerts.every((a) => a.type == AlertType.info)) {
      alerts.add(const HealthAlert(
        id: 'ok-vitals',
        type: AlertType.ok,
        title: 'Sinais vitais dentro do esperado',
        description:
            'Todas as métricas monitoradas estão na faixa de referência na última leitura.',
        timeLabel: 'Agora',
      ));
    }

    alerts.sort((a, b) => _severity(a.type).compareTo(_severity(b.type)));
    return alerts;
  }

  MedicationSchedule? _nextDose(List<MedicationSchedule> meds, DateTime now) {
    final minutesNow = now.hour * 60 + now.minute;
    MedicationSchedule? best;
    var bestDelta = 1 << 30;
    for (final m in meds) {
      final delta = (m.hour * 60 + m.minute) - minutesNow;
      if (delta >= 0 && delta < bestDelta) {
        best = m;
        bestDelta = delta;
      }
    }
    // Passou da última dose do dia: aponta para a primeira de amanhã.
    return best ?? (meds.isEmpty ? null : meds.first);
  }

  static int _severity(AlertType type) => switch (type) {
        AlertType.urgent => 0,
        AlertType.warning => 1,
        AlertType.info => 2,
        AlertType.ok => 3,
      };

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
