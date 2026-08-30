import 'package:flutter_test/flutter_test.dart';
import 'package:smartcare_flutter/core/error/failures.dart';
import 'package:smartcare_flutter/core/network/api_client.dart';
import 'package:smartcare_flutter/core/storage/local_cache.dart';
import 'package:smartcare_flutter/data/datasources/remote/vitals_remote_datasource.dart';
import 'package:smartcare_flutter/data/datasources/remote/weather_remote_datasource.dart';
import 'package:smartcare_flutter/data/repositories/health_repository_impl.dart';
import 'package:smartcare_flutter/domain/entities/entities.dart';

/// Datasource controlável: alterna entre responder e falhar.
class _FakeVitalsDataSource implements VitalsDataSource {
  _FakeVitalsDataSource(this.reading);

  VitalReading reading;
  AppFailure? failure;
  int calls = 0;

  @override
  Future<VitalReading> fetchLatest() async {
    calls++;
    if (failure != null) throw failure!;
    return reading;
  }
}

void main() {
  const baseline = VitalReading(
    heartRate: 72,
    spO2: 98.5,
    glucoseLevel: 104,
    bpSystolic: 118,
    bpDiastolic: 78,
    temperature: 36.6,
  );

  late _FakeVitalsDataSource vitals;
  late InMemoryCache cache;
  late HealthRepositoryImpl repository;

  setUp(() {
    vitals = _FakeVitalsDataSource(baseline);
    cache = InMemoryCache();
    repository = HealthRepositoryImpl(
      vitals: vitals,
      weather: WeatherRemoteDataSource(ApiClient()),
      cache: cache,
    );
  });

  test('leitura bem-sucedida vem da rede e é gravada no cache', () async {
    final result = await repository.loadVitals();

    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.fromCache, isFalse);
    expect(result.valueOrNull!.value, baseline);

    final cached = await cache.readJson(CacheKeys.vitals);
    expect(cached, isNotNull);
    expect(VitalReading.fromJson(cached!.value), baseline);
  });

  test('falha de rede com cache disponível devolve o dado salvo', () async {
    await repository.loadVitals(); // popula o cache
    vitals.failure = const NetworkFailure();

    final result = await repository.loadVitals();

    expect(result.isOk, isTrue, reason: 'a tela deve continuar utilizável');
    expect(result.valueOrNull!.fromCache, isTrue);
    expect(result.valueOrNull!.value, baseline);
    expect(result.valueOrNull!.updatedAt, isNotNull);
  });

  test('falha de rede sem cache devolve a falha tipada', () async {
    vitals.failure = const TimeoutFailure();

    final result = await repository.loadVitals();

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<TimeoutFailure>());
    expect(result.failureOrNull!.isRetryable, isTrue);
  });

  test('cache corrompido é descartado em vez de derrubar a leitura', () async {
    await cache.writeJson(CacheKeys.vitals, {'heartRate': 'texto inválido'});
    vitals.failure = const NetworkFailure();

    final result = await repository.loadVitals();

    expect(result.isErr, isTrue);
    expect(await cache.readJson(CacheKeys.vitals), isNull);
  });

  test('o perfil do paciente é carregado com sucesso', () async {
    final result = await repository.loadPatient();

    expect(result.isOk, isTrue);
    expect(result.valueOrNull!.name, isNotEmpty);
  });
}
