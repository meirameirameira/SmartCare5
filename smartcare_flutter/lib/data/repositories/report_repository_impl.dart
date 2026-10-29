import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../core/result/result.dart';
import '../../core/storage/local_cache.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/alert_engine.dart';
import '../../domain/services/clinical_report_engine.dart';
import '../datasources/remote/smarthas_api_datasource.dart';

/// Relatório vindo da API Smart HAS — e, com o perfil `oracle`, das rotinas
/// PL/SQL do banco.
///
/// Offline-first como o restante do app: cada relatório recebido fica em
/// cache por período; sem rede, a tela mostra o último relatório conhecido,
/// sinalizado como desatualizado, em vez de uma tela de erro.
class ApiReportRepository implements ReportRepository {
  ApiReportRepository(this._api, this._cache);

  final SmartHasApiDataSource _api;
  final LocalCache _cache;

  @override
  Future<Result<Sourced<ClinicalReport>>> loadReport(int periodDays) async {
    final key = CacheKeys.report(periodDays);
    try {
      final report = await _api.fetchReport(periodDays);
      try {
        await _cache.writeJson(key, report.toJson());
      } on CacheFailure catch (e) {
        debugPrint('[ReportRepository] cache indisponível: $e');
      }
      return Ok(Sourced(report, updatedAt: report.generatedAt));
    } catch (error) {
      final failure = error is AppFailure ? error : UnexpectedFailure(cause: error);
      // Regra de negócio recusada pelo servidor não é problema de rede:
      // mostrar cache aqui esconderia o erro real.
      if (failure is ServerFailure && failure.statusCode != 0 && failure.statusCode < 500) {
        return Err(failure);
      }
      final entry = await _cache.readJson(key);
      if (entry != null) {
        try {
          return Ok(Sourced(ClinicalReport.fromJson(entry.value),
              fromCache: true, updatedAt: entry.savedAt));
        } catch (e) {
          await _cache.remove(key);
        }
      }
      return Err(failure);
    }
  }
}

/// Relatório calculado no aparelho, usado em modo demonstração.
///
/// O histórico do período é reconstruído de forma determinística a partir da
/// leitura atual do wearable simulado (uma medição a cada 4 horas, como na
/// carga de dados do Oracle) e consolidado pelo [ClinicalReportEngine].
class LocalReportRepository implements ReportRepository {
  LocalReportRepository({
    required HealthRepository health,
    required DeliveryRepository delivery,
    this.engine = const ClinicalReportEngine(),
    this.alertEngine = const AlertEngine(),
    this.seed = 20261002,
  })  : _health = health,
        _delivery = delivery;

  final HealthRepository _health;
  final DeliveryRepository _delivery;
  final ClinicalReportEngine engine;
  final AlertEngine alertEngine;
  final int seed;

  static const readingsPerDay = 6;

  @override
  Future<Result<Sourced<ClinicalReport>>> loadReport(int periodDays) =>
      Result.guard(() async {
        final patient = (await _health.loadPatient()).valueOrNull;
        final vitals = await _health.loadVitals();
        final latest = vitals.valueOrNull?.value;
        if (patient == null || latest == null) {
          throw vitals.failureOrNull ??
              const UnexpectedFailure(cause: 'Paciente indisponível');
        }

        final now = DateTime.now();
        final history = demoHistory(latest, periodDays, now: now);
        final alerts = alertEngine
            .build(latest, now: now)
            .where((a) => a.type == AlertType.urgent || a.type == AlertType.warning)
            .toList();
        final order = (await _delivery.loadActiveOrder()).valueOrNull;

        final report = engine.build(
          patient: patient,
          history: history,
          periodDays: periodDays,
          openAlerts: alerts.length,
          urgentAlerts: alerts.where((a) => a.type == AlertType.urgent).length,
          alertsInPeriod: alerts.length,
          deliveriesTotal:
              order == null || order.status == DeliveryStatus.cancelled ? 0 : 1,
          deliveriesDelivered: order?.status == DeliveryStatus.delivered ? 1 : 0,
          now: now,
        );
        return Sourced(report,
            fromCache: vitals.valueOrNull?.fromCache ?? false, updatedAt: now);
      });

  /// Histórico plausível do período terminando exatamente em [latest].
  @visibleForTesting
  List<VitalReading> demoHistory(VitalReading latest, int periodDays,
      {required DateTime now}) {
    final rng = Random(seed + periodDays);
    final total = max(1, periodDays * readingsPerDay);
    final history = <VitalReading>[];

    var current = latest;
    // Caminha para trás no tempo a partir da leitura atual.
    for (var i = 0; i < total; i++) {
      history.add(current.copyWith(
        measuredAt: now.subtract(Duration(hours: 4 * i)),
      ));
      current = VitalReading(
        heartRate: _walk(rng, current.heartRate, 72, 4, 52, 118).round(),
        spO2: _round1(_walk(rng, current.spO2, 98, 0.5, 92, 100)),
        glucoseLevel: _walk(rng, current.glucoseLevel, 108, 9, 68, 190).round(),
        bpSystolic: _walk(rng, current.bpSystolic, 120, 4, 96, 152).round(),
        bpDiastolic: _walk(rng, current.bpDiastolic, 79, 3, 58, 98).round(),
        temperature: _round1(_walk(rng, current.temperature, 36.6, 0.15, 35.6, 38.4)),
      );
    }
    return history.reversed.toList(growable: false);
  }

  static double _walk(Random rng, num value, double base, double step,
      double min, double max) {
    final next = value + (rng.nextDouble() * 2 - 1) * step + (base - value) * 0.2;
    return next.clamp(min, max).toDouble();
  }

  static double _round1(double v) => (v * 10).round() / 10;
}
