import 'package:flutter/foundation.dart';

import '../../core/error/failures.dart';
import '../../core/result/result.dart';
import '../../core/storage/local_cache.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../datasources/local/demo_catalog.dart';
import '../datasources/remote/vitals_remote_datasource.dart';
import '../datasources/remote/weather_remote_datasource.dart';

/// Implementação **offline-first** do repositório de saúde.
///
/// Regra aplicada em todas as leituras remotas:
/// 1. tenta a fonte remota;
/// 2. em sucesso, grava no cache local e devolve marcando `fromCache: false`;
/// 3. em falha, devolve o último valor em cache marcado como `fromCache: true`
///    (a tela segue útil sem rede);
/// 4. só devolve `Err` quando não há nem rede nem cache.
class HealthRepositoryImpl implements HealthRepository {
  HealthRepositoryImpl({
    required VitalsDataSource vitals,
    required WeatherRemoteDataSource weather,
    required LocalCache cache,
    this.cacheTtl = const Duration(minutes: 10),
  })  : _vitals = vitals,
        _weather = weather,
        _cache = cache;

  final VitalsDataSource _vitals;
  final WeatherRemoteDataSource _weather;
  final LocalCache _cache;

  /// Janela em que o cache é considerado fresco o bastante para ser servido
  /// imediatamente, antes mesmo da revalidação de rede.
  final Duration cacheTtl;

  @override
  Future<Result<Patient>> loadPatient() async =>
      Result.guard(() async => DemoCatalog.patient);

  @override
  Future<Result<Sourced<VitalReading>>> loadVitals() =>
      _remoteFirst<VitalReading>(
        key: CacheKeys.vitals,
        fetch: _vitals.fetchLatest,
        encode: (v) => v.toJson(),
        decode: VitalReading.fromJson,
      );

  @override
  Future<Result<Sourced<String>>> loadWeather() async {
    final result = await _remoteFirst<WeatherSnapshot>(
      key: CacheKeys.weather,
      fetch: _weather.fetch,
      encode: (w) => w.toJson(),
      decode: WeatherSnapshot.fromJson,
    );
    return result.map((sourced) => Sourced(
          sourced.value.summary,
          fromCache: sourced.fromCache,
          updatedAt: sourced.updatedAt,
        ));
  }

  /// Núcleo da estratégia rede-com-fallback-de-cache, compartilhado por todas
  /// as leituras (evita repetir try/catch em cada método).
  Future<Result<Sourced<T>>> _remoteFirst<T>({
    required String key,
    required Future<T> Function() fetch,
    required Map<String, dynamic> Function(T value) encode,
    required T Function(Map<String, dynamic> json) decode,
  }) async {
    try {
      final fresh = await fetch();
      // Falha de escrita no cache não pode derrubar uma leitura bem-sucedida.
      try {
        await _cache.writeJson(key, encode(fresh));
      } on CacheFailure catch (e) {
        debugPrint('[HealthRepository] cache indisponível para "$key": $e');
      }
      return Ok(Sourced(fresh, updatedAt: DateTime.now()));
    } catch (error) {
      final failure =
          error is AppFailure ? error : UnexpectedFailure(cause: error);
      final cached = await _readCache(key, decode);
      if (cached != null) {
        debugPrint('[HealthRepository] "$key" servido do cache '
            '(${cached.age.inMinutes} min) após ${failure.runtimeType}');
        return Ok(Sourced(cached.value, fromCache: true, updatedAt: cached.savedAt));
      }
      return Err(failure);
    }
  }

  Future<CacheEntry<T>?> _readCache<T>(
    String key,
    T Function(Map<String, dynamic> json) decode,
  ) async {
    final entry = await _cache.readJson(key);
    if (entry == null) return null;
    try {
      return CacheEntry(value: decode(entry.value), savedAt: entry.savedAt);
    } catch (e) {
      debugPrint('[HealthRepository] cache inválido em "$key": $e');
      await _cache.remove(key);
      return null;
    }
  }
}
