import 'package:flutter/foundation.dart';
import '../models/models.dart';

class AnalyticsProvider extends ChangeNotifier {
  int selectedPeriod = 7;
  List<MetricSeries> metrics = [];
  List<AiInsight> insights = [];
  bool isLoading = true;

  AnalyticsProvider() {
    _load();
  }

  void selectPeriod(int days) {
    selectedPeriod = days;
    _load();
  }

  Future<void> _load() async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 400));

    metrics = [
      MetricSeries(
        label: 'Freq. Cardíaca',
        currentValue: '72',
        unit: 'bpm',
        trend: '-2 bpm vs semana passada',
        trendUp: false,
        weeklyData: _genData(72, 8, selectedPeriod),
        colorType: MetricColor.red,
      ),
      MetricSeries(
        label: 'SpO₂',
        currentValue: '98.5',
        unit: '%',
        trend: '+0.3% vs semana passada',
        trendUp: true,
        weeklyData: _genData(98, 2, selectedPeriod),
        colorType: MetricColor.blue,
      ),
      MetricSeries(
        label: 'Glicemia',
        currentValue: '104',
        unit: 'mg/dL',
        trend: '+8 mg/dL vs semana passada',
        trendUp: false,
        weeklyData: _genData(104, 20, selectedPeriod),
        colorType: MetricColor.amber,
      ),
      MetricSeries(
        label: 'Pressão Arterial',
        currentValue: '120/80',
        unit: 'mmHg',
        trend: 'Estável',
        trendUp: true,
        weeklyData: _genData(120, 10, selectedPeriod),
        colorType: MetricColor.green,
      ),
    ];

    insights = const [
      AiInsight(
        title: 'Pico glicêmico pós-almoço',
        description: 'Nos últimos 7 dias, sua glicemia sobe em média 18% entre 13h–15h. Considere caminhada leve após o almoço.',
        severity: InsightSeverity.warning,
      ),
      AiInsight(
        title: 'FC em repouso ideal',
        description: 'Frequência cardíaca de repouso média de 68 bpm — dentro do range saudável para sua faixa etária.',
        severity: InsightSeverity.info,
      ),
      AiInsight(
        title: 'Aderência medicamentosa excelente',
        description: '96% nos últimos 14 dias. Continue assim!',
        severity: InsightSeverity.info,
      ),
    ];

    isLoading = false;
    notifyListeners();
  }

  List<double> _genData(double base, double variance, int points) {
    final seed = base + variance * 0.1;
    return List.generate(points, (i) {
      final factor = 1.0 + (((i * 7 + 3) % 11) - 5) / 100 * variance / base;
      return (base * factor).clamp(base - variance, base + variance);
    });
  }
}
