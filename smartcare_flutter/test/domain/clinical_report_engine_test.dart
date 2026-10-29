import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';
import 'package:smartcare_flutter/domain/services/clinical_report_engine.dart';

void main() {
  const engine = ClinicalReportEngine();
  const patient = Patient(
    id: '1',
    name: 'Felipe Meira',
    initials: 'FM',
    age: 22,
    conditions: ['Hipertensao leve', 'Diabetes tipo 2'],
  );

  VitalReading reading({int glucose = 104, double spO2 = 98.5, required int hoursAgo}) =>
      VitalReading(
        heartRate: 72,
        spO2: spO2,
        glucoseLevel: glucose,
        bpSystolic: 118,
        bpDiastolic: 78,
        temperature: 36.6,
        measuredAt: DateTime(2026, 10, 2, 12).subtract(Duration(hours: hoursAgo)),
      );

  test('medias com uma casa decimal, como ROUND(AVG(x), 1) no Oracle', () {
    final report = engine.build(
      patient: patient,
      periodDays: 7,
      history: [
        reading(glucose: 100, hoursAgo: 8),
        reading(glucose: 105, hoursAgo: 4),
        reading(glucose: 111, hoursAgo: 0),
      ],
    );

    expect(report.readings, 3);
    expect(report.averages.glucose, 105.3);
    expect(report.averages.heartRate, 72.0);
    expect(report.engine, ReportEngine.device);
  });

  test('score atual vem da leitura mais recente, mesmo fora de ordem', () {
    final report = engine.build(
      patient: patient,
      periodDays: 7,
      history: [
        // A mais recente (0h) tem SpO2 critica: perde os 22 pontos do peso.
        reading(spO2: 84, hoursAgo: 0),
        reading(hoursAgo: 4),
      ],
    );

    expect(report.latestScore, 78);
    expect(report.riskLevel, 'BOM');
    expect(report.averageScore, 89.0);
  });

  test('tempo na faixa conta apenas glicemias entre 70 e 120 mg/dL', () {
    final history = [
      reading(glucose: 70, hoursAgo: 12), // limite inferior: na faixa
      reading(glucose: 120, hoursAgo: 8), // limite superior: na faixa
      reading(glucose: 121, hoursAgo: 4),
      reading(glucose: 65, hoursAgo: 0),
    ];

    expect(engine.glucoseTimeInRange(history), 50.0);
  });

  test('resumo segue o formato de FN_FORMATAR_RESUMO_PACIENTE', () {
    final report = engine.build(
      patient: patient,
      periodDays: 30,
      history: [reading(hoursAgo: 0)],
      openAlerts: 3,
      urgentAlerts: 2,
    );

    expect(
      report.summary,
      'Felipe Meira, 22 anos (Diabetes tipo 2, Hipertensao leve) | '
      'Score atual: 100/100 - EXCELENTE | '
      'Glicemia na faixa: 100,0% das leituras em 30 dias | '
      'Alertas abertos: 3 (2 urgentes)',
    );
  });

  test('sem leituras o relatorio nao inventa numeros', () {
    final report = engine.build(patient: patient, periodDays: 7, history: const []);

    expect(report.readings, 0);
    expect(report.latestScore, isNull);
    expect(report.averageScore, isNull);
    expect(report.glucoseTimeInRange, isNull);
    expect(report.riskLevel, 'SEM DADOS');
    expect(report.summary, contains('Score atual: sem leituras'));
  });

  test('taxa de entrega do consumo de medicamentos', () {
    final report = engine.build(
      patient: patient,
      periodDays: 30,
      history: const [],
      deliveriesTotal: 4,
      deliveriesDelivered: 3,
    );

    expect(report.deliveryRate, 75);
    expect(
      engine.build(patient: patient, periodDays: 30, history: const []).deliveryRate,
      isNull,
    );
  });

  test('relatorio sobrevive a ida e volta pelo cache (JSON)', () {
    final original = engine.build(
      patient: patient,
      periodDays: 7,
      history: [reading(hoursAgo: 0)],
      now: DateTime(2026, 10, 2, 12),
    );

    final restored = ClinicalReport.fromJson(original.toJson());

    expect(restored.summary, original.summary);
    expect(restored.latestScore, original.latestScore);
    expect(restored.averages.spO2, original.averages.spO2);
    expect(restored.engine, ReportEngine.device);
    expect(restored.generatedAt, original.generatedAt);
  });
}
