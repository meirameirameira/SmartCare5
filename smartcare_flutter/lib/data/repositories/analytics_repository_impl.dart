import 'dart:math';

import '../../core/result/result.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/health_score_engine.dart';
import '../datasources/local/demo_catalog.dart';

/// Séries históricas e insights de analytics.
///
/// A evolução em relação à versão anterior: o último ponto de cada série e o
/// valor exibido vêm da leitura **real** mais recente do wearable, e os
/// insights incluem um item gerado pelo motor de regras a partir da métrica
/// que mais está penalizando o score.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl({
    required HealthRepository health,
    this.scoreEngine = const HealthScoreEngine(),
    int seed = 20250830,
  })  : _health = health,
        _rng = Random(seed);

  final HealthRepository _health;
  final HealthScoreEngine scoreEngine;
  final Random _rng;

  @override
  Future<Result<List<MetricSeries>>> loadMetrics(int periodDays) =>
      Result.guard(() async {
        final vitals = (await _health.loadVitals()).valueOrNull?.value;

        return [
          _series(
            label: 'Freq. Cardíaca',
            unit: 'bpm',
            latest: (vitals?.heartRate ?? 72).toDouble(),
            baseline: 72,
            spread: 8,
            points: periodDays,
            color: MetricColor.red,
          ),
          _series(
            label: 'SpO₂',
            unit: '%',
            latest: vitals?.spO2 ?? 98.5,
            baseline: 98,
            spread: 1.5,
            points: periodDays,
            color: MetricColor.blue,
            decimals: 1,
          ),
          _series(
            label: 'Glicemia',
            unit: 'mg/dL',
            latest: (vitals?.glucoseLevel ?? 104).toDouble(),
            baseline: 104,
            spread: 18,
            points: periodDays,
            color: MetricColor.amber,
          ),
          _series(
            label: 'Pressão Sistólica',
            unit: 'mmHg',
            latest: (vitals?.bpSystolic ?? 120).toDouble(),
            baseline: 120,
            spread: 9,
            points: periodDays,
            color: MetricColor.green,
          ),
        ];
      });

  @override
  Future<Result<List<AiInsight>>> loadInsights(int periodDays) =>
      Result.guard(() async {
        final vitals = (await _health.loadVitals()).valueOrNull?.value;
        final insights = <AiInsight>[];

        if (vitals != null) {
          final score = scoreEngine.calculate(vitals);
          final worst = score.penalties.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          insights.add(AiInsight(
            title: 'Score de saúde: ${score.score}/100 (${score.label})',
            description: worst.isEmpty
                ? 'Nenhuma métrica fora da faixa de referência nos últimos '
                    '$periodDays dias monitorados.'
                : 'A métrica que mais reduz seu score agora é '
                    '${worst.first.key}. Priorize esse ponto nesta semana.',
            severity: switch (score.level) {
              HealthLevel.critical || HealthLevel.low => InsightSeverity.critical,
              HealthLevel.medium => InsightSeverity.warning,
              _ => InsightSeverity.info,
            },
          ));
        }

        insights.addAll(DemoCatalog.insights);
        return insights;
      });

  /// Gera a série do período terminando no valor real mais recente.
  MetricSeries _series({
    required String label,
    required String unit,
    required double latest,
    required double baseline,
    required double spread,
    required int points,
    required MetricColor color,
    int decimals = 0,
  }) {
    final data = List<double>.generate(points, (i) {
      // Interpola da linha de base até a leitura atual e aplica ruído estável.
      final progress = points == 1 ? 1.0 : i / (points - 1);
      final trendValue = baseline + (latest - baseline) * progress;
      final noise = (_rng.nextDouble() * 2 - 1) * spread * 0.35;
      return double.parse((trendValue + noise).toStringAsFixed(1));
    });
    if (data.isNotEmpty) data[data.length - 1] = latest;

    final first = data.first;
    final delta = latest - first;
    final improving = switch (label) {
      'Freq. Cardíaca' || 'Glicemia' || 'Pressão Sistólica' => delta <= 0,
      _ => delta >= 0,
    };

    return MetricSeries(
      label: label,
      currentValue: latest.toStringAsFixed(decimals),
      unit: unit,
      trend: delta.abs() < 0.05
          ? 'Estável no período'
          : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(decimals)} $unit '
              'vs. início do período',
      trendUp: improving,
      weeklyData: data,
      colorType: color,
    );
  }
}
