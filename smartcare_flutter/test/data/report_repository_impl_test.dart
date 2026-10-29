import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/core/network/api_client.dart';
import 'package:smartcare_flutter/core/storage/local_cache.dart';
import 'package:smartcare_flutter/data/datasources/remote/smarthas_api_datasource.dart';
import 'package:smartcare_flutter/data/repositories/logistics_repository_impl.dart';
import 'package:smartcare_flutter/data/repositories/report_repository_impl.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';

import '../presentation/fake_health_repository.dart';

/// API falsa: devolve um relatório ou lança a falha configurada.
class _FakeApi extends SmartHasApiDataSource {
  _FakeApi() : super(SmartHasApiSession(ApiClient(maxRetries: 0), InMemoryCache()));

  AppFailure? failure;
  int calls = 0;

  @override
  Future<ClinicalReport> fetchReport(int periodDays) async {
    calls++;
    if (failure != null) throw failure!;
    return ClinicalReport(
      patientName: 'Felipe Meira',
      periodDays: periodDays,
      generatedAt: DateTime(2026, 10, 2, 14, 30),
      readings: 180,
      averages: const VitalAverages(glucose: 108.2),
      latestScore: 91,
      averageScore: 88.7,
      riskLevel: 'EXCELENTE',
      glucoseTimeInRange: 76.5,
      openAlerts: 1,
      urgentAlerts: 0,
      alertsInPeriod: 2,
      deliveriesTotal: 2,
      deliveriesDelivered: 1,
      summary: 'Felipe Meira, 22 anos',
      engine: ReportEngine.oraclePlsql,
    );
  }
}

void main() {
  group('ApiReportRepository', () {
    late _FakeApi api;
    late InMemoryCache cache;
    late ApiReportRepository repository;

    setUp(() {
      api = _FakeApi();
      cache = InMemoryCache();
      repository = ApiReportRepository(api, cache);
    });

    test('relatorio do servidor e salvo no cache do periodo', () async {
      final result = await repository.loadReport(30);

      expect(result.valueOrNull!.fromCache, isFalse);
      expect(result.valueOrNull!.value.engine, ReportEngine.oraclePlsql);
      expect(await cache.readJson(CacheKeys.report(30)), isNotNull);
      expect(await cache.readJson(CacheKeys.report(7)), isNull);
    });

    test('sem rede devolve o ultimo relatorio salvo, marcado como cache', () async {
      await repository.loadReport(30);
      api.failure = const NetworkFailure();

      final result = await repository.loadReport(30);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull!.fromCache, isTrue);
      expect(result.valueOrNull!.value.latestScore, 91);
    });

    test('sem rede e sem cache devolve a falha', () async {
      api.failure = const NetworkFailure();

      final result = await repository.loadReport(30);

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('erro de regra de negocio (4xx) nao e mascarado pelo cache', () async {
      await repository.loadReport(30);
      api.failure = const ServerFailure(422);

      final result = await repository.loadReport(30);

      expect(result.failureOrNull, isA<ServerFailure>());
    });
  });

  group('LocalReportRepository (modo demonstracao)', () {
    late LocalReportRepository repository;

    setUp(() {
      repository = LocalReportRepository(
        health: FakeHealthRepository(),
        delivery: DeliveryRepositoryImpl(),
      );
    });

    test('consolida 6 leituras por dia e termina na leitura atual', () async {
      final report = (await repository.loadReport(7)).valueOrNull!.value;

      expect(report.engine, ReportEngine.device);
      expect(report.readings, 7 * LocalReportRepository.readingsPerDay);
      // A leitura atual do wearable (estavel) e a mais recente do historico.
      expect(report.latestScore, 100);
      expect(report.patientName, 'Felipe Meira');
      expect(report.glucoseTimeInRange, inInclusiveRange(0, 100));
      expect(report.deliveriesTotal, 1);
    });

    test('historico e deterministico para o mesmo periodo', () {
      final now = DateTime(2026, 10, 2, 12);
      final a = repository.demoHistory(FakeHealthRepository.stable, 7, now: now);
      final b = repository.demoHistory(FakeHealthRepository.stable, 7, now: now);

      expect(a.map((r) => r.glucoseLevel), b.map((r) => r.glucoseLevel));
      expect(a.last.measuredAt, now);
      expect(a.first.measuredAt, now.subtract(const Duration(hours: 4 * 41)));
    });

    test('falha do wearable sem cache vira falha do relatorio', () async {
      final health = FakeHealthRepository()..failure = const NetworkFailure();
      final offline = LocalReportRepository(health: health, delivery: DeliveryRepositoryImpl());

      final result = await offline.loadReport(7);

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });
}
