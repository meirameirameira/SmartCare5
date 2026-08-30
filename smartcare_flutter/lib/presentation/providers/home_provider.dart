import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../core/state/view_state.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/alert_engine.dart';
import '../../domain/services/health_score_engine.dart';

/// Fotografia consistente do dashboard em um instante.
///
/// Agrupar tudo em um objeto imutável evita o estado "meio atualizado" que a
/// versão anterior produzia ao mutar campos soltos entre `notifyListeners()`.
class HomeSnapshot {
  const HomeSnapshot({
    required this.patient,
    required this.vitals,
    required this.score,
    required this.evaluations,
    required this.alerts,
    this.weather,
    this.fromCache = false,
    this.updatedAt,
  });

  final Patient patient;
  final VitalReading vitals;
  final HealthScore score;
  final List<VitalEvaluation> evaluations;
  final List<HealthAlert> alerts;
  final String? weather;
  final bool fromCache;
  final DateTime? updatedAt;

  HomeSnapshot copyWith({String? weather}) => HomeSnapshot(
        patient: patient,
        vitals: vitals,
        score: score,
        evaluations: evaluations,
        alerts: alerts,
        weather: weather ?? this.weather,
        fromCache: fromCache,
        updatedAt: updatedAt,
      );
}

/// Provider do dashboard.
///
/// Evoluções em relação à versão anterior:
///  - depende da **interface** [HealthRepository] (injetada), não de services
///    estáticos — o que torna a tela testável com um repositório falso;
///  - o score e os alertas são calculados pelos motores de domínio a partir da
///    leitura corrente, em vez de constantes;
///  - erros viram estado visível ([ViewState.failed]) com dados obsoletos
///    preservados, em vez de `catch (_) {}`;
///  - o polling pode ser pausado quando o app vai para segundo plano.
class HomeProvider extends ChangeNotifier {
  HomeProvider({
    required HealthRepository repository,
    HealthScoreEngine scoreEngine = const HealthScoreEngine(),
    AlertEngine alertEngine = const AlertEngine(),
    this.pollInterval = const Duration(seconds: 15),
    bool autoStart = true,
  })  : _repository = repository,
        _scoreEngine = scoreEngine,
        _alertEngine = alertEngine {
    if (autoStart) {
      unawaited(refresh());
      startPolling();
    }
  }

  final HealthRepository _repository;
  final HealthScoreEngine _scoreEngine;
  final AlertEngine _alertEngine;

  /// Intervalo entre leituras automáticas do wearable.
  final Duration pollInterval;

  ViewState<HomeSnapshot> _state = const ViewState.loading();
  ViewState<HomeSnapshot> get state => _state;

  Timer? _timer;
  int? _previousScore;
  bool _refreshing = false;

  // ── API compatível com as telas ────────────────────────────────────────────

  HomeSnapshot? get snapshot => _state.dataOrNull;
  Patient? get patient => snapshot?.patient;
  VitalReading? get vitals => snapshot?.vitals;
  HealthScore? get healthScore => snapshot?.score;
  List<VitalEvaluation> get evaluations => snapshot?.evaluations ?? const [];
  List<HealthAlert> get alerts => snapshot?.alerts ?? const [];
  String? get weatherInfo => snapshot?.weather;
  bool get isLoading => _state.isLoading && snapshot == null;
  AppFailure? get failure => _state.failureOrNull;

  /// Indica que os dados exibidos vieram do cache local (sem rede).
  bool get isOffline => snapshot?.fromCache ?? false;
  DateTime? get lastUpdated => snapshot?.updatedAt;

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  // ── Ciclo de dados ─────────────────────────────────────────────────────────

  /// Recarrega paciente, sinais vitais e clima; recalcula score e alertas.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    if (snapshot == null) {
      _state = const ViewState.loading();
      notifyListeners();
    }

    try {
      final patientResult = await _repository.loadPatient();
      final vitalsResult = await _repository.loadVitals();

      final failure = patientResult.failureOrNull ?? vitalsResult.failureOrNull;
      if (failure != null) {
        _state = ViewState.failed(failure, staleData: snapshot);
        notifyListeners();
        return;
      }

      final sourced = vitalsResult.valueOrNull!;
      final vitals = sourced.value;
      final score = _scoreEngine.calculate(vitals, previousScore: _previousScore);
      _previousScore = score.score;

      _state = ViewState.ready(
        HomeSnapshot(
          patient: patientResult.valueOrNull!,
          vitals: vitals,
          score: score,
          evaluations: _scoreEngine.evaluateVitals(vitals),
          alerts: _alertEngine.build(vitals),
          weather: snapshot?.weather,
          fromCache: sourced.fromCache,
          updatedAt: sourced.updatedAt ?? DateTime.now(),
        ),
        updatedAt: sourced.updatedAt,
        fromCache: sourced.fromCache,
      );
      notifyListeners();

      // Clima é complementar: falha aqui não invalida o dashboard.
      unawaited(_loadWeather());
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _loadWeather() async {
    final result = await _repository.loadWeather();
    final current = snapshot;
    if (current == null) return;
    result.when(
      ok: (sourced) {
        _state = ViewState.ready(current.copyWith(weather: sourced.value));
        notifyListeners();
      },
      err: (f) => debugPrint('[HomeProvider] clima indisponível: ${f.message}'),
    );
  }

  /// Inicia a leitura periódica do wearable.
  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  /// Suspende o polling (app em segundo plano ou tela fora de foco).
  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isPolling => _timer != null;

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
