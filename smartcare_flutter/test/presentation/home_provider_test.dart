import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';
import 'package:smartcare_flutter/presentation/providers/home_provider.dart';

import 'fake_health_repository.dart';

void main() {
  late FakeHealthRepository repository;
  late HomeProvider provider;

  setUp(() {
    repository = FakeHealthRepository();
    provider = HomeProvider(repository: repository, autoStart: false);
  });

  tearDown(() => provider.dispose());

  test('carrega paciente, score e alertas a partir do repositório', () async {
    await provider.refresh();

    expect(provider.patient, isNotNull);
    expect(provider.vitals, FakeHealthRepository.stable);
    expect(provider.healthScore!.score, 100);
    expect(provider.alerts, isNotEmpty);
    expect(provider.evaluations.length, 6);
    expect(provider.isLoading, isFalse);
    expect(provider.failure, isNull);
  });

  test('sinal alterado aparece como alerta e derruba o score', () async {
    repository.reading =
        FakeHealthRepository.stable.copyWith(glucoseLevel: 210);

    await provider.refresh();

    expect(provider.healthScore!.score, lessThan(100));
    expect(
      provider.alerts.any((a) => a.type == AlertType.urgent),
      isTrue,
    );
  });

  test('dados vindos do cache marcam o modo offline', () async {
    repository.fromCache = true;

    await provider.refresh();

    expect(provider.isOffline, isTrue);
    expect(provider.lastUpdated, isNotNull);
  });

  test('falha vira estado visível e preserva a última leitura válida', () async {
    await provider.refresh();
    final previousScore = provider.healthScore!.score;

    repository.failure = const NetworkFailure();
    await provider.refresh();

    expect(provider.failure, isA<NetworkFailure>());
    expect(provider.healthScore!.score, previousScore,
        reason: 'os dados antigos continuam disponíveis para a tela');
  });

  test('a tendência compara com o score da leitura anterior', () async {
    await provider.refresh();
    repository.reading = FakeHealthRepository.stable.copyWith(spO2: 85);

    await provider.refresh();

    expect(provider.healthScore!.trend, TrendDirection.down);
  });

  test('o clima é carregado sem bloquear o dashboard', () async {
    await provider.refresh();
    await Future<void>.delayed(Duration.zero);

    expect(provider.weatherInfo, contains('°C'));
  });

  test('polling pode ser iniciado e interrompido', () {
    expect(provider.isPolling, isFalse);
    provider.startPolling();
    expect(provider.isPolling, isTrue);
    provider.stopPolling();
    expect(provider.isPolling, isFalse);
  });
}
