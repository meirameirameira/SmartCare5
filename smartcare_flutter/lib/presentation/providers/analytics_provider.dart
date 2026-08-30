import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';

/// Provider da tela de analytics.
class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._repository, {bool autoStart = true}) {
    if (autoStart) load();
  }

  final AnalyticsRepository _repository;

  static const periodOptions = <int>[7, 14, 30];

  int selectedPeriod = 7;
  List<MetricSeries> metrics = const [];
  List<AiInsight> insights = const [];
  bool isLoading = true;
  AppFailure? failure;

  void selectPeriod(int days) {
    if (selectedPeriod == days) return;
    selectedPeriod = days;
    load();
  }

  Future<void> load() async {
    isLoading = true;
    failure = null;
    notifyListeners();

    final metricsResult = await _repository.loadMetrics(selectedPeriod);
    final insightsResult = await _repository.loadInsights(selectedPeriod);

    metrics = metricsResult.valueOrNull ?? metrics;
    insights = insightsResult.valueOrNull ?? insights;
    failure = metricsResult.failureOrNull ?? insightsResult.failureOrNull;
    isLoading = false;
    notifyListeners();
  }
}
