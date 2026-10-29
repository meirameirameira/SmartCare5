import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/domain/services/health_score_engine.dart';

/// As faixas clínicas do app precisam ser as mesmas carregadas no Oracle
/// (`database/oracle/08_carga_dados.sql`): é dali que as functions PL/SQL
/// calculam o score que o relatório mostra.
void main() {
  test('faixas do HealthScoreEngine iguais as da tabela VITAL_REFERENCE_RANGE', () {
    final seed = File('../database/oracle/08_carga_dados.sql').readAsStringSync();
    final insert = RegExp(
      r"INSERT INTO vital_reference_range VALUES \('(\w+)',\s*'[^']+',\s*'[^']+',"
      r'\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*([\d.]+),\s*(\d+),\s*\d+\);',
    );

    final sql = {
      for (final m in insert.allMatches(seed))
        m.group(1)!: [
          double.parse(m.group(2)!),
          double.parse(m.group(3)!),
          double.parse(m.group(4)!),
          double.parse(m.group(5)!),
          double.parse(m.group(6)!),
        ],
    };

    const app = {
      'HEART_RATE': HealthScoreEngine.heartRate,
      'SPO2': HealthScoreEngine.spO2,
      'GLUCOSE': HealthScoreEngine.glucose,
      'SYSTOLIC': HealthScoreEngine.systolic,
      'DIASTOLIC': HealthScoreEngine.diastolic,
      'TEMPERATURE': HealthScoreEngine.temperature,
    };

    expect(sql.keys, unorderedEquals(app.keys));
    app.forEach((code, range) {
      expect(
        sql[code],
        [
          range.normalMin,
          range.normalMax,
          range.attentionMin,
          range.attentionMax,
          range.weight.toDouble(),
        ],
        reason: 'faixa $code divergente entre o app e o Oracle',
      );
    });
  });
}
