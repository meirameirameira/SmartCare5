import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/analytics_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/entities.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<AnalyticsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics de Saúde')),
      body: Column(
        children: [
          // Period selector
          Container(
            color: SmartCareTheme.primaryGreenDark,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [7, 14, 30].map((days) {
                final selected = p.selectedPeriod == days;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: GestureDetector(
                    onTap: () => p.selectPeriod(days),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$days dias',
                          style: TextStyle(
                              color: selected
                                  ? SmartCareTheme.primaryGreen
                                  : Colors.white,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 12)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: p.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...p.metrics.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _MetricCard(metric: m),
                        )),
                        _sectionLabel('insights da IA'),
                        ...p.insights.map((i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _InsightCard(insight: i),
                        )),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            letterSpacing: 1.2, color: Colors.grey)),
  );
}

class _MetricCard extends StatelessWidget {
  final MetricSeries metric;
  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final color = switch (metric.colorType) {
      MetricColor.red   => SmartCareTheme.dangerRed,
      MetricColor.blue  => SmartCareTheme.accentBlue,
      MetricColor.amber => SmartCareTheme.warnAmber,
      MetricColor.green => SmartCareTheme.primaryGreen,
    };

    final spots = metric.weeklyData.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(metric.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(metric.trend,
                        style: TextStyle(
                            fontSize: 11,
                            color: metric.trendUp ? Colors.green : Colors.red)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(metric.currentValue,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: color)),
                  Text(metric.unit,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 70,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AiInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (insight.severity) {
      InsightSeverity.critical => (SmartCareTheme.dangerRed, '🔴'),
      InsightSeverity.warning  => (SmartCareTheme.warnAmber, '⚠️'),
      InsightSeverity.info     => (SmartCareTheme.accentBlue, 'ℹ️'),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Text(insight.description,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
