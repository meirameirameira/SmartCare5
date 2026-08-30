import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';
import 'package:smartcare_flutter/domain/services/alert_engine.dart';

import 'health_score_engine_test.dart' show vitals;

void main() {
  const engine = AlertEngine();
  final noon = DateTime(2026, 8, 30, 12, 0);

  test('paciente estável recebe alerta de tudo certo', () {
    final alerts = engine.build(vitals(), now: noon);

    expect(alerts.any((a) => a.type == AlertType.ok), isTrue);
    expect(alerts.any((a) => a.type == AlertType.urgent), isFalse);
  });

  test('sinal crítico gera alerta urgente com orientação de emergência', () {
    final alerts = engine.build(vitals(spO2: 84), now: noon);

    final urgent = alerts.firstWhere((a) => a.type == AlertType.urgent);
    expect(urgent.title, contains('SpO₂'));
    expect(urgent.description, contains('192'));
  });

  test('alertas são ordenados por severidade', () {
    final alerts = engine.build(
      vitals(spO2: 84, glucose: 150),
      now: noon,
    );

    final types = alerts.map((a) => a.type).toList();
    expect(types.first, AlertType.urgent);
    expect(types.contains(AlertType.warning), isTrue);
    expect(types.indexOf(AlertType.warning),
        lessThan(types.indexOf(AlertType.info)));
  });

  test('a próxima dose do dia é a mais próxima do horário atual', () {
    final alerts = engine.build(vitals(), now: DateTime(2026, 8, 30, 9, 30));
    final medication = alerts.firstWhere((a) => a.type == AlertType.info);

    expect(medication.title, contains('14:00'));
  });

  test('após a última dose do dia, aponta para a primeira do dia seguinte', () {
    final alerts = engine.build(vitals(), now: DateTime(2026, 8, 30, 22, 0));
    final medication = alerts.firstWhere((a) => a.type == AlertType.info);

    expect(medication.title, contains('08:00'));
  });

  test('a geração é determinística para o mesmo instante', () {
    final first = engine.build(vitals(glucose: 150), now: noon);
    final second = engine.build(vitals(glucose: 150), now: noon);

    expect(first.map((a) => a.id), second.map((a) => a.id));
  });
}
