import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';
import 'package:smartcare_flutter/domain/services/health_score_engine.dart';

VitalReading vitals({
  int heartRate = 72,
  double spO2 = 98.5,
  int glucose = 104,
  int systolic = 118,
  int diastolic = 78,
  double temperature = 36.6,
}) =>
    VitalReading(
      heartRate: heartRate,
      spO2: spO2,
      glucoseLevel: glucose,
      bpSystolic: systolic,
      bpDiastolic: diastolic,
      temperature: temperature,
    );

void main() {
  const engine = HealthScoreEngine();

  group('classificação de sinais vitais', () {
    test('valores na faixa de referência são normais', () {
      final evaluations = engine.evaluateVitals(vitals());
      expect(
        evaluations.every((e) => e.status == VitalStatus.normal),
        isTrue,
        reason: 'linha de base do paciente deve estar toda normal',
      );
    });

    test('SpO2 de 93% entra em atenção e 88% em crítico', () {
      expect(HealthScoreEngine.spO2.classify(93), VitalStatus.attention);
      expect(HealthScoreEngine.spO2.classify(88), VitalStatus.critical);
    });

    test('glicemia de 150 é atenção e 200 é crítica', () {
      expect(HealthScoreEngine.glucose.classify(150), VitalStatus.attention);
      expect(HealthScoreEngine.glucose.classify(200), VitalStatus.critical);
    });
  });

  group('cálculo do score', () {
    test('paciente estável recebe 100 e nível excelente', () {
      final score = engine.calculate(vitals());
      expect(score.score, 100);
      expect(score.level, HealthLevel.excellent);
      expect(score.label, 'EXCELENTE');
      expect(score.penalties, isEmpty);
    });

    test('sinal em atenção desconta parte do peso da métrica', () {
      final score = engine.calculate(vitals(glucose: 150));
      // Peso da glicemia = 22; atenção desconta 40% -> 9 pontos.
      expect(score.penalties['Glicemia'], 9);
      expect(score.score, 91);
    });

    test('sinal crítico desconta o peso total da métrica', () {
      final score = engine.calculate(vitals(spO2: 85));
      expect(score.penalties['SpO₂'], HealthScoreEngine.spO2.weight);
      expect(score.score, 100 - HealthScoreEngine.spO2.weight);
    });

    test('múltiplas alterações acumulam e derrubam o nível', () {
      final score = engine.calculate(
        vitals(spO2: 86, glucose: 210, heartRate: 130, systolic: 165),
      );
      expect(score.score, lessThan(60));
      expect(score.penalties.length, greaterThanOrEqualTo(4));
      expect(score.level,
          anyOf(HealthLevel.low, HealthLevel.critical, HealthLevel.medium));
    });

    test('score nunca sai do intervalo 0–100', () {
      final worst = engine.calculate(vitals(
        heartRate: 200,
        spO2: 60,
        glucose: 400,
        systolic: 220,
        diastolic: 130,
        temperature: 41,
      ));
      expect(worst.score, inInclusiveRange(0, 100));
    });
  });

  group('tendência', () {
    test('variação de até 2 pontos é considerada estável', () {
      final score = engine.calculate(vitals(), previousScore: 99);
      expect(score.trend, TrendDirection.stable);
    });

    test('queda relevante em relação à leitura anterior é sinalizada', () {
      final score = engine.calculate(vitals(spO2: 85), previousScore: 100);
      expect(score.trend, TrendDirection.down);
    });

    test('melhora relevante é sinalizada como alta', () {
      final score = engine.calculate(vitals(), previousScore: 60);
      expect(score.trend, TrendDirection.up);
    });
  });

  group('faixas de nível', () {
    test('mapeiam o score para o rótulo esperado', () {
      expect(HealthScoreEngine.levelFor(95), HealthLevel.excellent);
      expect(HealthScoreEngine.levelFor(80), HealthLevel.good);
      expect(HealthScoreEngine.levelFor(65), HealthLevel.medium);
      expect(HealthScoreEngine.levelFor(45), HealthLevel.low);
      expect(HealthScoreEngine.levelFor(20), HealthLevel.critical);
      expect(HealthScoreEngine.labelFor(HealthLevel.critical), 'CRÍTICO');
    });
  });
}
